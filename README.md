# te — minimal text editor

A minimal plain-text editor built with Zig and GTK4.

## Prerequisites

- [Zig](https://ziglang.org/) >= 0.16.0
- GTK4 development libraries
- `pkg-config` in PATH

### macOS (Homebrew)

```sh
brew install zig gtk4
```

### Debian / Ubuntu

```sh
sudo apt install zig libgtk-4-dev
```

## Build & Run

```sh
zig build run
```

Or build first, then run separately:

```sh
zig build
./zig-out/bin/te
```

## Keyboard Shortcuts

| Shortcut         | Action             |
|------------------|--------------------|
| Ctrl+N           | New tab            |
| Ctrl+O           | Open file (new tab)|
| Ctrl+S           | Save file          |
| Ctrl+W           | Close current tab  |
| Ctrl+Tab         | Next tab           |
| Ctrl+Shift+Tab   | Previous tab       |

## Architecture

GTK4 headers cannot be translated by Zig 0.16's `translate-c` (see
[upstream issue](https://codeberg.org/ziglang/translate-c/issues/341)).
This project works around the limitation by declaring the ~45 needed
GTK4/GLib C functions as `extern fn` with opaque pointer types — no
header translation or `@cImport` required.
