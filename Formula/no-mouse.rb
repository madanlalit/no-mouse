# Homebrew Formula for NoMouse
# To use: brew tap yourusername/tap && brew install no-mouse

class NoMouse < Formula
  desc "Keyboard-driven mouse control for macOS"
  homepage "https://github.com/madanlalit/no-mouse"
  url "https://github.com/madanlalit/no-mouse/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "56d940e8c1d9cc04bcac997b7d4680d39275e345f7a1aa41181bd27db50e2832"
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

  def post_install
    # Create symlink in /Applications for easy access
    app_path = prefix/"NoMouse.app"
    target = Pathname.new("/Applications/NoMouse.app")
    
    # Remove existing symlink if present
    target.unlink if target.symlink?
    
    # Create new symlink
    target.make_symlink(app_path)
    ohai "Symlink created: /Applications/NoMouse.app"
  end

  def post_uninstall
    # Remove symlink from /Applications on uninstall
    target = Pathname.new("/Applications/NoMouse.app")
    target.unlink if target.symlink?
    ohai "Symlink removed: /Applications/NoMouse.app"
  end

  def caveats
    <<~EOS
      NoMouse requires permissions to function:
      
      1. Accessibility: System Settings → Privacy & Security → Accessibility
      2. Input Monitoring: System Settings → Privacy & Security → Input Monitoring
      
      Add NoMouse.app to both lists and enable them.
      
      NoMouse has been linked to /Applications.
      To start: open /Applications/NoMouse.app
      
      Or use Spotlight (⌘ Space) and search "NoMouse"
    EOS
  end

  test do
    assert_predicate bin/"NoMouse", :executable?
  end
end
