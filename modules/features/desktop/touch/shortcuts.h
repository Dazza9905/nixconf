#ifndef TOUCH_SHORTCUTS_H
#define TOUCH_SHORTCUTS_H
#include <stdbool.h>
#include <stdint.h>
void touch_shortcuts_init(void);
bool touch_shortcut(uint8_t mods, uint32_t key);
#endif
