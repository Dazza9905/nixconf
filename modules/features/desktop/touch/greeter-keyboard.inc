// Built into the greeter's own scene: no external input injection at login.
#include <glib.h>
#include <xkbcommon/xkbcommon.h>

void GreeterSurface::touchKeyboardKey(std::uint32_t sym, char32_t character) {
  if (!m_passwordVisible || !m_passwordField || !m_passwordField->inputArea()->enabled()) return;
  closeMenus();
  m_inputDispatcher.setFocus(m_passwordField->inputArea());
  if (sym == XKB_KEY_Return) {
    tryAuthenticate();
    return;
  }
  m_inputDispatcher.keyEvent(sym ? sym : xkb_utf32_to_keysym(character), character, 0, true, false);
  requestLayout();
}

void GreeterSurface::buildTouchKeyboard() {
  auto makeButton = [this](std::string_view text, std::function<void()> action) {
    auto button = std::make_unique<Button>();
    button->setText(text);
    button->setFontSize(18.0f);
    button->setContentAlign(ButtonContentAlign::Center);
    button->setOnClick(std::move(action));
    button->inputArea()->setFocusable(false);
    button->setZIndex(31);
    button->setAnimationManager(nullptr);
    auto* pointer = button.get();
    m_root.addChild(std::move(button));
    return pointer;
  };
  m_touchToggle = makeButton("Keyboard", [this]() {
    m_touchOpen = !m_touchOpen;
    requestLayout();
  });
  auto panel = std::make_unique<Box>();
  m_touchPanel = panel.get();
  panel->setZIndex(30);
  m_root.addChild(std::move(panel));

  const std::u32string rows[] = {
    U"1234567890-=", U"qwertyuiop[]", U"asdfghjkl;'\\", U"zxcvbnm,./",
    U"áäčďéíľĺňóôŕšťúýž"
  };
  const std::u32string shifted[] = {
    U"!@#$%^&*()_+", U"QWERTYUIOP{}", U"ASDFGHJKL:\"|", U"ZXCVBNM<>?",
    U"ÁÄČĎÉÍĽĹŇÓÔŔŠŤÚÝŽ"
  };
  for (std::size_t row = 0; row < 5; row++) {
    for (std::size_t column = 0; column < rows[row].size(); column++) {
      const char32_t normal = rows[row][column], upper = shifted[row][column];
      auto* button = makeButton("", [this, normal, upper]() {
        touchKeyboardKey(0, m_touchShift ? upper : normal);
        m_touchShift = false;
        requestLayout();
      });
      m_touchKeys.push_back({button, normal, upper, row, column, rows[row].size()});
    }
  }
  m_touchShiftButton = makeButton("Shift", [this]() {m_touchShift = !m_touchShift; requestLayout();});
  m_touchControls = {
    m_touchShiftButton,
    makeButton("Space", [this]() {touchKeyboardKey(0, U' ');}),
    makeButton("Left", [this]() {touchKeyboardKey(XKB_KEY_Left, 0);}),
    makeButton("Right", [this]() {touchKeyboardKey(XKB_KEY_Right, 0);}),
    makeButton("Backspace", [this]() {touchKeyboardKey(XKB_KEY_BackSpace, 0);}),
    makeButton("Enter", [this]() {touchKeyboardKey(XKB_KEY_Return, 0);}),
  };
}

void GreeterSurface::layoutTouchKeyboard(float ox, float oy, float sw, float sh) {
  const bool visible = m_touchOpen && m_passwordVisible;
  m_touchToggle->setVisible(m_passwordVisible);
  m_touchToggle->setPosition(ox + 16.0f, oy + 16.0f);
  m_touchToggle->setSize(144.0f, 44.0f);
  m_touchToggle->layout(*m_renderContext);
  m_touchToggle->setSelected(visible);
  const float width = std::max(240.0f, std::min(sw - 32.0f, 960.0f));
  const float height = std::min(316.0f, sh * 0.42f);
  const float x = ox + (sw - width) / 2.0f;
  const float y = oy + sh - height - 72.0f;
  m_touchPanel->setVisible(visible);
  m_touchPanel->setPosition(x, y);
  m_touchPanel->setSize(width, height);
  m_touchPanel->setStyle(RoundedRectStyle{
    .fill = colorForRole(ColorRole::SurfaceVariant),
    .border = colorForRole(ColorRole::Outline),
    .fillMode = FillMode::Solid,
    .radius = 12.0f,
    .borderWidth = 1.0f,
  });
  const float gap = 6.0f, padding = 12.0f;
  const float keyHeight = (height - padding * 2.0f - gap * 5.0f) / 6.0f;
  const bool enabled = m_passwordField->inputArea()->enabled();
  for (auto& key : m_touchKeys) {
    key.button->setVisible(visible);
    key.button->setEnabled(enabled);
    const char32_t value = m_touchShift ? key.shifted : key.normal;
    char label[7] = {0};
    const int length = g_unichar_to_utf8(value, label);
    key.button->setText(std::string_view(label, length));
    const float keyWidth = (width - padding * 2.0f - gap * (key.count - 1)) / key.count;
    key.button->setPosition(x + padding + key.column * (keyWidth + gap), y + padding + key.row * (keyHeight + gap));
    key.button->setSize(keyWidth, keyHeight);
    key.button->layout(*m_renderContext);
  }
  const float controlWidth = (width - padding * 2.0f - gap * 5.0f) / 6.0f;
  for (std::size_t column = 0; column < m_touchControls.size(); column++) {
    auto* button = m_touchControls[column];
    button->setVisible(visible);
    button->setEnabled(enabled);
    button->setPosition(x + padding + column * (controlWidth + gap), y + padding + 5.0f * (keyHeight + gap));
    button->setSize(controlWidth, keyHeight);
    button->layout(*m_renderContext);
  }
  m_touchShiftButton->setSelected(m_touchShift);
}
