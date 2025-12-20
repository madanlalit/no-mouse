# Cask for NoMouse - Pre-built binary (instant install)
# Usage: brew install --cask no-mouse

cask "no-mouse" do
  version "1.1.0"
  sha256 "e97f4471ea7d98c0ab8c46629c442cb80131715dbc8056ce754dcbd4f08ae064"

  url "https://github.com/madanlalit/no-mouse/releases/download/v#{version}/NoMouse.dmg"
  name "NoMouse"
  desc "Keyboard-driven mouse control for macOS"
  homepage "https://github.com/madanlalit/no-mouse"

  depends_on macos: ">= :ventura"

  app "NoMouse.app"

  caveats <<~EOS
    NoMouse requires permissions to function:

    1. Accessibility: System Settings → Privacy & Security → Accessibility
    2. Input Monitoring: System Settings → Privacy & Security → Input Monitoring

    Add NoMouse.app to both lists and enable them.
  EOS
end
