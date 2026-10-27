# Keebart ZMK Firmware

This repository contains the ZMK firmware configuration for Keebart wireless
split keyboards. It includes board definitions, default keymaps, ZMK Studio
support, Sharp Memory-in-Pixel display support, RGB underglow, and GitHub
Actions firmware builds.

- Maintainer: [Keebart](https://github.com/Keebart)
- Firmware: [ZMK](https://zmk.dev/)
- Miryoku firmware: [Keebart/miryoku_zmk](https://github.com/Keebart/miryoku_zmk)
- Online keymap editor: [ZMK Keymap Editor](https://nickcoutsos.github.io/keymap-editor/)
- Runtime editor: [ZMK Studio](https://zmk.studio/)

## Supported keyboards

| Keyboard | Layout | Board targets | Bluetooth name |
| --- | --- | --- | --- |
| [Corne Choc Pro BT](https://keebart.com/products/corne-wireless) | 6-column | `corne_choc_pro_left`, `corne_choc_pro_right` | `Corne Choc BT` |
| Corne Choc Pro BT 5-Col | 5-column | `corne_choc_pro_5col_left`, `corne_choc_pro_5col_right` | `Corne Choc BT` |
| [Piantor Pro BT](https://keebart.com/products/piantor-wireless) | 6-column | `piantor_pro_bt_left`, `piantor_pro_bt_right` | `Piantor Pro BT` |
| Piantor Pro BT 5-Col | 5-column | `piantor_pro_bt_5col_left`, `piantor_pro_bt_5col_right` | `Piantor Pro BT` |
| [Sofle Choc Pro BT](https://keebart.com/products/sofle-wireless) | 6-column | `sofle_choc_pro_left`, `sofle_choc_pro_right` | `Sofle Choc BT` |

The shortened Bluetooth names fit ZMK's 16-character device-name limit while
making wireless models identifiable in the host's Bluetooth menu.

## Firmware variants

Corne and Piantor have separate 6-column and 5-column firmware targets. The
6-column targets retain the standard keymaps. Targets ending in `_5col` use a
compact keymap designed specifically for boards without the outer columns.

Separate firmware is intentional. ZMK Studio can switch between physical
layouts in one firmware, but it stores one runtime keymap rather than two
independent defaults. Separate targets also give the ZMK Keymap Editor one
unambiguous source keymap and geometry for each keyboard variant.

Select matching firmware for both halves. Do not mix a regular target with an
`_5col` target.

## Default 5-column keymap

The compact keymap uses home-row modifiers and thumb keys that tap common keys
or hold dedicated layers.

### Home-row modifiers

Tap a home-row key to type its letter. Hold it to use its modifier.

| Key | Hold action | Key | Hold action |
| --- | --- | --- | --- |
| `A` | Left GUI | `J` | Right Shift |
| `S` | Left Alt | `K` | Right Ctrl |
| `D` | Left Ctrl | `L` | Right Alt |
| `F` | Left Shift | `'` | Right GUI |

The mod-taps use a 200 ms tapping term and ZMK's `tap-preferred` flavor to avoid
turning ordinary same-hand typing rolls into modifiers.

### Thumb keys

| Tap | Hold |
| --- | --- |
| `Esc` | Media layer |
| `Space` | Navigation layer |
| `Tab` | Function layer |
| `Enter` | Symbol layer |
| `Backspace` | Number layer |
| `Delete` | Adjust layer |

### Layers

| Layer | Main contents |
| --- | --- |
| `QWERTY` | Letters, punctuation, home-row modifiers, and layer-tap thumbs |
| `NAV` | Arrow keys, Home, End, Page Up/Down, Insert, Caps Lock, and modifiers |
| `MEDIA` | Playback, volume, and RGB controls including hue down/up |
| `NUM` | Numpad-style digits, brackets, semicolon, equals, backslash, and grave |
| `SYM` | Braces, parentheses, operators, colon, and shifted symbols |
| `FUN` | F1-F12, Print Screen, Scroll Lock, Pause, and modifiers |
| `ADJUST` | Bluetooth profiles, RGB controls, reset, bootloader, and Studio unlock |

To unlock ZMK Studio on a 5-column build, hold the `Delete` thumb key and press
`C`. Reset and bootloader are on `Z` and `X` on the same layer.

The source files are:

- `config/corne_choc_pro_5col.keymap`
- `config/piantor_pro_bt_5col.keymap`

Matching board-default copies are kept under `boards/arm/*_5col/`.

## Miryoku firmware

Alternative firmware using the [Miryoku](https://github.com/manna-harbour/miryoku)
layout is maintained in
[Keebart/miryoku_zmk](https://github.com/Keebart/miryoku_zmk). Its GitHub Actions
workflows build Miryoku firmware for the standard Corne Choc Pro BT, Piantor
Pro BT, and Sofle Choc Pro BT targets.

The Miryoku repository loads this repository as an external ZMK module. Board
definitions and the `sharp_mip` display shield remain here, while Miryoku owns
the keymap and physical mappings. Its keyboard workflows select `sharp_mip` as
an extra shield, so the custom display remains available in Miryoku firmware.

Run the matching workflow from the Miryoku repository's **Actions** tab and
flash the generated left and right firmware files to their corresponding
halves. Miryoku firmware is an alternative to the default keymaps built by
this repository; it is not an additional runtime-selectable keymap.

## Building firmware

The GitHub Actions workflow builds all targets on every push and pull request.
It can also be started manually from the repository's **Actions** tab. Download
the merged `firmware` artifact after the build finishes.

The build matrix is defined in `build.yaml`. Normal firmware uses the custom
`sharp_mip` shield on every keyboard. Corne and Piantor use its default
orientation; Sofle enables the 180-degree rotation in its board configuration.
The central, left-side builds include ZMK Studio support.

### Local build with Docker

`build.sh` builds the targets from `build.yaml` locally in the official
`zmkfirmware/zmk-build-arm` Docker image, so no Zephyr SDK installation is
needed. Docker must be running.

```sh
./build.sh                 # every target in build.yaml
./build.sh sofle           # targets whose board or artifact name contains "sofle"
./build.sh --no-reset sofle  # skip the settings_reset targets
./build.sh --list corne    # show matching targets without building
./build.sh --update        # refresh ZMK/Zephyr sources
```

Firmware is written to `firmware/<artifact-name>.uf2`. The first run downloads
ZMK and Zephyr into the `zmk-workspace` Docker volume and takes several
minutes; later builds reuse it. The workspace is refreshed automatically when
`config/west.yml` changes.

### Local build with west

Without Docker, first create a normal ZMK west workspace using the manifest
in `config/west.yml`. From the workspace root, run a command such as:

```sh
west build -s zmk/app -d build/corne-5col-left \
  -b corne_choc_pro_5col_left \
  -S studio-rpc-usb-uart -- \
  -DZMK_CONFIG=/path/to/zmk-config/config \
  -DZMK_EXTRA_MODULES=/path/to/zmk-config \
  -DSHIELD=sharp_mip \
  -DCONFIG_ZMK_STUDIO=y
```

Change the board target as required. The resulting firmware is written to
`build/corne-5col-left/zephyr/zmk.uf2`.

## Configuration settings

User-adjustable firmware settings belong in the matching `config/*.conf` file.
This includes the keyboard name, power management, RGB defaults, display idle
behavior, and an optional pointing setting. The files under `boards/` describe
the keyboard hardware and its internal defaults; normal users should not edit
them.

## Flashing

The halves use different firmware because the left half is the central side
and the right half is the peripheral side.

1. Download or build the firmware package.
2. Enter the bootloader on the right half and copy its matching right-side UF2
   file to the USB mass-storage device.
3. Enter the bootloader on the left half and copy its matching left-side UF2
   file.
4. Reconnect the keyboard and pair it with the host if necessary.

### Entering the bootloader

The bootloader is a small program that lets the computer copy new firmware
onto a half. Flash each half on its own:

1. Turn the half on and connect it to the computer with a USB-C cable. Only the
   half being flashed needs to be connected.
2. Enter the bootloader with one of these methods:
   - **Reset button:** press the small physical reset button on that half
     **twice quickly** (about half a second apart). A single press only
     restarts the keyboard firmware.
   - **Bootloader key:** press the `&bootloader` key in the active keymap.
     It enters the bootloader on the half it is pressed on. In every default
     keymap this key is on the left half, so it only works for the left half;
     use the reset button for the right half.

     | Keymap | Bootloader key (left half) |
     | --- | --- |
     | Corne / Piantor 6-column | Hold Lower (`NUMBER` layer), then press `V` |
     | Corne / Piantor 5-column | Hold `Delete` (`ADJUST` layer), then press `X` |
     | Sofle | None; use the reset button |

3. A USB drive appears on the computer (in Finder on macOS). The keys and the
   display stop responding while the half is in the bootloader; this is
   expected.
4. Copy the matching `.uf2` file onto that drive, by dragging it in Finder or
   with `cp firmware/<file>.uf2 /Volumes/<drive-name>/`.
5. The half restarts by itself as soon as the copy finishes and the drive
   disappears. macOS may then report that the disk was not ejected properly.
   This is normal and can be ignored.

If no drive appears, check that the USB-C cable carries data (some cables are
charge-only), try the double press again a little faster, and make sure the
half is switched on.

### Resetting saved settings

The build artifact also contains `settings_reset` firmware for the standard
Corne, Piantor, and Sofle targets. Use it when split pairing or stored settings
prevent normal operation:

The standard Corne and Piantor settings-reset files can also be used before
reflashing their matching 5-column firmware because the hardware is the same.

1. Flash the appropriate settings-reset firmware to a half.
2. Allow it to boot and clear the saved settings.
3. Immediately flash the normal firmware for that half again.
4. Repeat for the other half when resetting split pairing.

Settings-reset firmware is temporary and is not a usable keyboard firmware.

## Bluetooth won't reconnect

A Bluetooth pairing is stored on **both** the computer and the keyboard.
Removing the keyboard on the computer deletes only the computer's copy; the
keyboard profile still expects the old pairing and refuses the new one, so the
computer reports that it couldn't connect. Clear that profile on the keyboard
too, then pair again:

1. On the keyboard, select the Bluetooth profile used by that computer.
2. Press the Bluetooth clear key (`BT_CLR`). It clears only the selected
   profile; the other profiles and their computers are not affected.
3. On the computer, remove every entry for the keyboard in its Bluetooth
   settings, then turn Bluetooth off and on again.
4. With the same profile still selected, pair the keyboard from the computer.

| Keymap | Select profile | Clear selected profile |
| --- | --- | --- |
| Sofle | Hold the left encoder button and rotate it | Hold Raise, press the top-left key |
| Corne / Piantor 6-column | Hold Lower, press `A` `S` `D` `F` `G` (profiles 1-5) | Hold Lower, press `Z` |
| Corne / Piantor 5-column | Hold `Delete`, press `W` `E` `R` `T` (profiles 1-4) | Hold `Delete`, press `Q` |

If it still fails, restart the keyboard half that connects to the computer
(the left, central half). On Windows, also check Device Manager > View > Show
hidden devices > Bluetooth and uninstall any leftover entry for the keyboard
before pairing again. As a last resort, use the settings-reset firmware above;
it clears all pairings, so every computer must be paired again.

## Editing keymaps

### ZMK Keymap Editor

The [ZMK Keymap Editor](https://nickcoutsos.github.io/keymap-editor/) edits the
source `.keymap` files in this repository. Choose the file matching the
keyboard and column count. The accompanying JSON files in `config/` provide
the correct visual geometry.

Editing and committing a source keymap triggers a new GitHub Actions build.
This is the recommended workflow for maintaining and distributing defaults.

### ZMK Studio

[ZMK Studio](https://zmk.studio/) edits the runtime keymap stored on the
keyboard. Connect the left half directly by USB, unlock Studio from the
keymap, and select the device in the browser.

Studio changes do not update the `.keymap` source file. Conversely, flashing
new firmware may not replace a Studio-edited keymap because the runtime state
is saved. Use **Restore Stock Settings** in Studio after changing between
6-column and 5-column firmware or whenever the compiled default should be
loaded again.

## Power management

Deep sleep is enabled on every half. The keyboard enters deep sleep after one
hour (`3600000` ms) without activity and wakes when a key is pressed. The long
timeout avoids the keyboard appearing to sleep during normal breaks while
still conserving battery during extended inactivity. Change these settings in
the matching `config/*.conf` file.

## RGB controls

RGB underglow is enabled with a conservative maximum brightness. On the
5-column keymap, hold `Esc` for the Media layer:

- `Q`: hue down (`RGB_HUD`)
- `W`: hue up (`RGB_HUI`)
- `E` / `R`: saturation down/up
- `T`: cycle effect

Brightness and toggle controls are on the bottom row of the same layer. The
Adjust layer also contains the complete RGB control set for testing.

## Rotary encoders

Corne Choc Pro supports four encoder definitions:

1. Volume down/up
2. Page Up/Down
3. Previous/next media track
4. Volume down/up

Sofle Choc Pro uses the right encoder for volume. Its push button has three
actions: tap to mute, double-tap to switch the underglow on/off, and hold
(about half a second) while rotating to dim or brighten the underglow. With the
underglow on, it turns off when the keyboard is idle and comes back on when you
type; switched off, it stays off while typing. The left
encoder selects the Bluetooth profile: hold its push button and rotate to
switch to the previous/next profile, then release. Rotating the left encoder
without holding the button does nothing.

### Changing the number or order of layers

Bindings saved on the keyboard (ZMK Studio) are stored by layer number and are
applied on top of the compiled keymap. After flashing a keymap that inserts,
removes, or reorders layers, use **Restore Stock Settings** in ZMK Studio or
flash the `settings_reset` firmware (see [Resetting saved settings](#resetting-saved-settings)),
otherwise saved bindings end up on the wrong layers. Adding a layer at the end
of the keymap avoids this.

## Sofle per-profile layout

The Sofle keymap targets two host keyboard layouts and switches between them
automatically with the Bluetooth profile:

| Bluetooth profile | Host input source | Keymap layers |
| --- | --- | --- |
| 2 | Windows **Belgian (Period)** | `win`, `win lower`, `win raise` over the macOS layers |
| 1, 3, 4, 5 | macOS **French** | `default`, `lower`, `raise` |

Each Windows layer only overrides the keys that differ from macOS French
(`@`, `#`, `{ }`, `[ ]`, `|`, `\`, `~`, `< >`, `` ` ``, and Ctrl instead of Cmd
for undo/cut/copy/paste)
and is otherwise transparent.

The switch is done by a small module in this repository (`src/profile_layer.c`)
that activates a layer while a given profile is selected. It is enabled in
`config/sofle_choc_pro.conf`:

```ini
CONFIG_ZMK_PROFILE_LAYER=y
CONFIG_ZMK_PROFILE_LAYER_PROFILE=1   # 0-based: 1 = profile 2 on the display
CONFIG_ZMK_PROFILE_LAYER_LAYER=1     # the WIN layer
```
