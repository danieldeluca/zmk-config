#!/usr/bin/env bash
#
# Build ZMK firmware locally with Docker, using the same targets as build.yaml.
#
# Usage:
#   ./build.sh                 build every target in build.yaml
#   ./build.sh sofle           build targets whose board or artifact name contains "sofle"
#   ./build.sh sofle corne     several filters are OR-ed
#   ./build.sh --no-reset sofle  skip settings_reset targets
#   ./build.sh --update        force "west update" (refresh ZMK/Zephyr sources)
#   ./build.sh --list          show the targets that would be built
#
# Firmware is written to ./firmware/<artifact-name>.uf2
# ZMK/Zephyr sources and build caches live in the Docker volume "zmk-workspace".

set -eo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${ZMK_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
VOLUME="${ZMK_VOLUME:-zmk-workspace}"

filters=()
skip_reset=0
force_update=0
list_only=0

for arg in "$@"; do
  case "$arg" in
    --no-reset) skip_reset=1 ;;
    --update)   force_update=1 ;;
    --list)     list_only=1 ;;
    -h|--help)  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         echo "Unknown option: $arg" >&2; exit 1 ;;
    *)          filters+=("$arg") ;;
  esac
done

# Parse build.yaml "include" entries into: board|shield|snippet|cmake-args|artifact-name
parse_matrix() {
  awk '
    function flush() {
      if (board != "") print board "|" shield "|" snippet "|" cmake "|" artifact
      board = shield = snippet = cmake = artifact = ""
    }
    function value(line) {
      sub(/^[^:]*:[ \t]*/, "", line)
      gsub(/^["\x27]|["\x27][ \t]*$/, "", line)
      return line
    }
    /^[ \t]*#/ { next }
    /^[ \t]*-[ \t]*board:/ { flush(); board = value($0); next }
    /^[ \t]*board:/        { board = value($0); next }
    /^[ \t]*shield:/       { shield = value($0); next }
    /^[ \t]*snippet:/      { snippet = value($0); next }
    /^[ \t]*cmake-args:/   { cmake = value($0); next }
    /^[ \t]*artifact-name:/ { artifact = value($0); next }
    END { flush() }
  ' "$REPO_DIR/build.yaml"
}

targets=()
while IFS='|' read -r board shield snippet cmake artifact; do
  # Same default artifact name as ZMK's build-user-config workflow
  [[ -z "$artifact" ]] && artifact="${shield:+$shield-}${board}-zmk"

  [[ $skip_reset -eq 1 && "$shield" == *settings_reset* ]] && continue

  if [[ ${#filters[@]} -gt 0 ]]; then
    match=0
    for f in "${filters[@]}"; do
      [[ "$board" == *"$f"* || "$artifact" == *"$f"* ]] && match=1
    done
    [[ $match -eq 0 ]] && continue
  fi

  targets+=("$board|$shield|$snippet|$cmake|$artifact")
done < <(parse_matrix)

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "No targets in build.yaml match: ${filters[*]:-<all>}" >&2
  exit 1
fi

echo "Targets:"
for t in "${targets[@]}"; do
  IFS='|' read -r board shield snippet cmake artifact <<< "$t"
  printf '  %-34s board=%s shield=%s\n' "$artifact" "$board" "${shield:-none}"
done
[[ $list_only -eq 1 ]] && exit 0

command -v docker >/dev/null || { echo "Docker is required but not installed." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker Desktop and retry." >&2; exit 1; }

mkdir -p "$REPO_DIR/firmware"

# Script executed inside the container
{
  cat <<EOF
set -eo pipefail
cd /workspace
if [ ! -d .west ] || ! cmp -s /zmk-config/config/west.yml config/west.yml || [ "$force_update" = 1 ]; then
  echo "==> Initialising ZMK workspace (first run or west.yml changed)"
  mkdir -p config
  cp /zmk-config/config/west.yml config/west.yml
  [ -d .west ] || west init -l config
  west update --fetch-opt=--filter=tree:0
  west zephyr-export
fi
failed=()
EOF
  for t in "${targets[@]}"; do
    IFS='|' read -r board shield snippet cmake artifact <<< "$t"
    cat <<EOF
echo
echo "==> Building $artifact"
if west build -s zmk/app -d "build/$artifact" -b "$board" ${snippet:+-S "$snippet"} -- \\
     -DZMK_CONFIG=/zmk-config/config -DZMK_EXTRA_MODULES=/zmk-config \\
     ${shield:+-DSHIELD="$shield"} $cmake; then
  cp "build/$artifact/zephyr/zmk.uf2" "/zmk-config/firmware/$artifact.uf2"
  echo "    -> firmware/$artifact.uf2"
else
  failed+=("$artifact")
fi
EOF
  done
  cat <<'EOF'
echo
if [ ${#failed[@]} -gt 0 ]; then
  echo "FAILED: ${failed[*]}"
  exit 1
fi
echo "All builds succeeded."
EOF
} | docker run --rm -i \
      -v "$REPO_DIR":/zmk-config \
      -v "$VOLUME":/workspace \
      "$IMAGE" bash -s
