# NoMouse 

A keyboard-driven mouse control app for macOS. Navigate your screen with just the keyboard — no mouse needed.

## Features

- **Grid Navigation** — 26×26 grid overlay with two-letter jump (676 positions)
- **Sub-Grid Refinement** — Single-letter precision after initial jump
- **Free Movement** — Arrow keys with acceleration
- **All Click Types** — Left, right, middle, double-click
- **Scroll & Drag** — Full scroll and click-and-drag support
- **Multi-Monitor** — Works across all displays
- **Menu Bar App** — Minimal footprint, no Dock icon
- **Privacy First** — No network, no telemetry, fully local

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission
- Input Monitoring permission

## Installation

### Using Setup Script (Recommended)
```bash
git clone https://github.com/madanlalit/no-mouse.git
cd no-mouse
chmod +x setup.sh
./setup.sh
```

### Homebrew
```bash
brew tap madanlalit
brew install no-mouse
```

### Build Manually
```bash
swift build -c release
cp .build/release/NoMouse NoMouse.app/Contents/MacOS/
open NoMouse.app
```

## Quick Start

1. Launch NoMouse (appears in menu bar)
2. Grant permissions when prompted
3. Press **⌃ Space** to activate
4. Type two letters (e.g., `MN`) → cursor jumps
5. Type one letter for precision → cursor refines
6. Press **Return** to click

## Keyboard Shortcuts

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

## Permissions

NoMouse requires two permissions:

1. **Accessibility** — To move the cursor and simulate clicks
2. **Input Monitoring** — To capture keyboard input globally

Grant these in **System Settings → Privacy & Security**.

## Building from Source

```bash
# Clone
git clone https://github.com/madanlalit/no-mouse.git
cd no-mouse

# Build release
swift build -c release

# Create app bundle
mkdir -p NoMouse.app/Contents/MacOS
cp .build/release/NoMouse NoMouse.app/Contents/MacOS/

# Run
open NoMouse.app
```

## License

MIT License — see [LICENSE](LICENSE)

## Contributing

Contributions welcome! Please open an issue to discuss changes before submitting a PR.
