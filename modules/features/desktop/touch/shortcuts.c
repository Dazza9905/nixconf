#include "shortcuts.h"
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static int input_fd = -1;

static void cleanup(void)
{
    if (input_fd >= 0) {
        ioctl(input_fd, UI_DEV_DESTROY);
        close(input_fd);
    }
}

void touch_shortcuts_init(void)
{
    input_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
    if (input_fd < 0) {
        perror("touch keyboard: cannot open /dev/uinput for system shortcuts");
        return;
    }
    if (ioctl(input_fd, UI_SET_EVBIT, EV_KEY) < 0) goto fail;
    for (int key = 1; key <= KEY_MAX; key++)
        if (ioctl(input_fd, UI_SET_KEYBIT, key) < 0) goto fail;
    struct uinput_setup setup = {0};
    setup.id.bustype = BUS_VIRTUAL;
    snprintf(setup.name, sizeof(setup.name), "Touch keyboard shortcuts");
    if (ioctl(input_fd, UI_DEV_SETUP, &setup) < 0 ||
        ioctl(input_fd, UI_DEV_CREATE) < 0) goto fail;
    atexit(cleanup);
    fprintf(stderr, "Touch keyboard system shortcuts ready\n");
    return;
fail:
    perror("touch keyboard: uinput setup failed");
    close(input_fd);
    input_fd = -1;
}

static void key_event(unsigned code, int pressed)
{
    struct input_event events[2] = {
        {.type = EV_KEY, .code = code, .value = pressed},
        {.type = EV_SYN, .code = SYN_REPORT},
    };
    if (write(input_fd, events, sizeof(events)) != sizeof(events))
        perror("touch keyboard: shortcut write failed");
}

bool touch_shortcut(uint8_t mods, uint32_t key)
{
    if (input_fd < 0 || !(mods & (8 | 64))) return false;
    const unsigned masks[] = {1, 4, 8, 64, 128};
    const unsigned keys[] = {KEY_LEFTSHIFT, KEY_LEFTCTRL, KEY_LEFTALT, KEY_LEFTMETA, KEY_RIGHTALT};
    for (unsigned i = 0; i < 5; i++)
        if (mods & masks[i]) key_event(keys[i], 1);
    key_event(key, 1);
    key_event(key, 0);
    for (int i = 4; i >= 0; i--)
        if (mods & masks[i]) key_event(keys[i], 0);
    return true;
}
