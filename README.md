<div align="center">

# NoMouse

**Navigate your screen with just the keyboard — no mouse needed.**

A keyboard-driven mouse control app for macOS that brings precision and speed to cursor navigation.

[![GitHub Stars](https://img.shields.io/github/stars/madanlalit/no-mouse?style=social)](https://github.com/madanlalit/no-mouse)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/madanlalit/no-mouse/blob/main/LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Shortcuts](#️-keyboard-shortcuts)

</div>

---

## 🚀 Quick Start

1. **Download** NoMouse from [Releases](https://github.com/madanlalit/no-mouse/releases)
2. **Move** `NoMouse.app` to Applications folder
3. **Launch** and grant permissions
4. **Press** `⌃ Space` to activate grid overlay
5. **Type** two letters (e.g., `MN`) → cursor jumps to that position

That's it! You're now controlling your mouse with just your keyboard.

---

## 🎯 Features

- **⚡ Grid Navigation** — 26×26 grid overlay with two-letter jump (676 positions)
- **🎯 Sub-Grid Refinement** — Single-letter precision after initial jump
- **🔄 Free Movement** — Arrow keys with acceleration
- **🖱️ All Click Types** — Left, right, middle, double-click
- **📜 Scroll & Drag** — Full scroll and click-and-drag support
- **🖥️ Multi-Monitor** — Works seamlessly across all displays
- **🎛️ Menu Bar App** — Minimal footprint, no Dock icon
- **🔒 Privacy First** — No network, no telemetry, fully local

---

## 📦 Installation

### Option 1: Direct Download (Recommended)

1. Download `NoMouse-X.X.X.zip` from [Releases](https://github.com/madanlalit/no-mouse/releases)
2. Unzip and move `NoMouse.app` to your **Applications** folder
3. **Right-click** `NoMouse.app` → **Open** (important for first launch!)
4. Click **Open** in the security dialog

> [!WARNING]
> **macOS Gatekeeper Notice**: Since this app isn't signed with an Apple Developer certificate, macOS will show a security warning. Right-clicking and selecting "Open" bypasses this for apps from identified developers you trust.

### Option 2: Homebrew

```bash
brew tap madanlalit/homebrew-tap
brew install --cask no-mouse
```

> [!NOTE]
> After installing via Homebrew, you may still need to right-click the app in Applications and choose 'Open' on first launch.

### Option 3: Build from Source

```bash
git clone https://github.com/madanlalit/no-mouse.git
cd no-mouse
swift build -c release
mkdir -p NoMouse.app/Contents/MacOS
cp .build/release/NoMouse NoMouse.app/Contents/MacOS/
open NoMouse.app
```

<details>
<summary>🔧 Advanced: Remove quarantine flag</summary>

If right-click → Open doesn't work, run this in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/NoMouse.app
```

</details>

---

## ⌨️ Keyboard Shortcuts

### Activation

| Shortcut | Action |
|----------|--------|
| **⌃ Space** | Activate grid overlay |
| **Escape** | Deactivate / Exit |
| **Tab** | Toggle grid ↔ free move mode |

### Grid Navigation

| Shortcut | Action |
|----------|--------|
| **A-Z + A-Z** | Jump to grid cell |
| **A-Z** (in refinement) | Precise position within cell |
| **Backspace** | Back to full grid / clear input |

### Mouse Clicks

| Shortcut | Action |
|----------|--------|
| **Return** | Left click |
| **⇧ Return** | Right click |
| **⌃ Return** | Middle click |

### Movement

| Shortcut | Action |
|----------|--------|
| **↑ ↓ ← →** | Move cursor |
| **⇧ + Arrow** | Fast movement (5×) |
| **⌥ + Arrow** | Slow/precise movement |
| *Hold arrow key* | Accelerates over time |

### Scroll

| Shortcut | Action |
|----------|--------|
| **⌘ + ↑↓** | Scroll up/down |
| **⌘ + ←→** | Scroll left/right |
| **⌘ + ⇧ + Arrow** | Fast scroll (3×) |

### Drag

| Shortcut | Action |
|----------|--------|
| **D** | Toggle drag mode on/off |

---

## 🔐 Permissions

NoMouse requires two macOS permissions to function:

1. **Accessibility** — Allows NoMouse to move the cursor and simulate clicks
2. **Input Monitoring** — Enables global keyboard shortcut capture

You'll be prompted to grant these on first launch. If needed, you can enable them manually in:  
**System Settings → Privacy & Security → Accessibility/Input Monitoring**

> [!IMPORTANT]
> Both permissions are essential for NoMouse to work. Your privacy is protected — all processing happens locally on your device.

---

## 🤝 Contributing

Contributions are welcome! Please open an issue to discuss changes before submitting a PR.

**Found NoMouse helpful?** Give us a ⭐ on [GitHub](https://github.com/madanlalit/no-mouse)!

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ for keyboard enthusiasts**

</div>
