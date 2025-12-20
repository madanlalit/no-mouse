# Cask for NoMouse - Pre-built binary (instant install)
# Usage: brew install --cask no-mouse

cask "no-mouse" do
  version "1.1.0"
  sha256 "8c3448cf33159b2ab8e6e32f6f1629c5a90de1cb110e11709a25fc483d073618"

  url "https://github.com/madanlalit/no-mouse/releases/download/v#{version}/NoMouse-#{version}.zip"
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
