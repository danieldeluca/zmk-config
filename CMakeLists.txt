# Bluetooth profiles and the keymap live on the central half only
if(CONFIG_ZMK_PROFILE_LAYER AND CONFIG_ZMK_BLE AND (CONFIG_ZMK_SPLIT_ROLE_CENTRAL OR NOT CONFIG_ZMK_SPLIT))
  target_sources(app PRIVATE src/profile_layer.c)
endif()
