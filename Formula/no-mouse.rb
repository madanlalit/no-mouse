# Homebrew Formula for NoMouse
# To use: brew tap yourusername/tap && brew install no-mouse

class NoMouse < Formula
  desc "Keyboard-driven mouse control for macOS"
  homepage "https://github.com/madanlalit/no-mouse"
  url "https://github.com/madanlalit/no-mouse/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "da6c66814d3d4293bac48dd063843b619b4048b07dfc324d117b283fbe8fd755"
  license "MIT"

  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/NoMouse"
    
    # Create app bundle
    app_contents = prefix/"NoMouse.app/Contents"
    (app_contents/"MacOS").mkpath
    (app_contents/"MacOS").install_symlink bin/"NoMouse"
    
    # Create Info.plist
    (app_contents/"Info.plist").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>NoMouse</string>
        <key>CFBundleIdentifier</key>
        <string>com.nomouse.app</string>
        <key>CFBundleName</key>
        <string>NoMouse</string>
        <key>CFBundleVersion</key>
        <string>#{version}</string>
        <key>LSUIElement</key>
        <true/>
        <key>NSAccessibilityUsageDescription</key>
        <string>NoMouse needs Accessibility permission to control the mouse cursor.</string>
      </dict>
      </plist>
    EOS
  end

  def caveats
    <<~EOS
      NoMouse requires permissions to function:
      
      1. Accessibility: System Settings → Privacy & Security → Accessibility
      2. Input Monitoring: System Settings → Privacy & Security → Input Monitoring
      
      Add NoMouse.app to both lists and enable them.
      
      To start NoMouse:
        open #{prefix}/NoMouse.app
    EOS
  end

  test do
    assert_predicate bin/"NoMouse", :executable?
  end
end
