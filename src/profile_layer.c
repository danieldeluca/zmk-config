/*
 * Activate a keymap layer while a given Bluetooth profile is selected.
 *
 * SPDX-License-Identifier: MIT
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

#include <zmk/event_manager.h>
#include <zmk/events/ble_active_profile_changed.h>
#include <zmk/keymap.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

static int profile_layer_listener(const zmk_event_t *eh) {
    const struct zmk_ble_active_profile_changed *ev = as_zmk_ble_active_profile_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    // Keymaps without the layer (e.g. settings_reset) are left alone
    if (CONFIG_ZMK_PROFILE_LAYER_LAYER >= ZMK_KEYMAP_LAYERS_LEN) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    bool wanted = ev->index == CONFIG_ZMK_PROFILE_LAYER_PROFILE;
    if (wanted != zmk_keymap_layer_active(CONFIG_ZMK_PROFILE_LAYER_LAYER)) {
        LOG_DBG("Profile %d selected, %s layer %d", ev->index, wanted ? "activating" : "deactivating",
                CONFIG_ZMK_PROFILE_LAYER_LAYER);
        if (wanted) {
            zmk_keymap_layer_activate(CONFIG_ZMK_PROFILE_LAYER_LAYER);
        } else {
            zmk_keymap_layer_deactivate(CONFIG_ZMK_PROFILE_LAYER_LAYER);
        }
    }

    return ZMK_EV_EVENT_BUBBLE;
}

ZMK_LISTENER(profile_layer, profile_layer_listener);
ZMK_SUBSCRIPTION(profile_layer, zmk_ble_active_profile_changed);
