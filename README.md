# CopyWheel

<p align="center">
  <a href="https://github.com/weselski/copywheel/releases/latest"><img src="https://img.shields.io/github/v/release/weselski/copywheel?label=release" alt="Latest release"></a>
  <a href="https://github.com/weselski/copywheel/releases"><img src="https://img.shields.io/github/downloads/weselski/copywheel/total" alt="Downloads"></a>
  <a href="https://github.com/weselski/copywheel/actions"><img src="https://github.com/weselski/copywheel/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT"></a>
</p>

<p align="center">
  <img src="docs/demo.gif" width="360" alt="CopyWheel demo: a radial menu appears at the cursor, hovering highlights segments, clicking copies the snippet" />
</p>

A tiny, native macOS menu bar app that does exactly one thing: press a hotkey and a **radial menu appears at your mouse cursor** — click a segment and that snippet is **copied to your clipboard**.

No Electron, no automation platform. Just a wheel of your snippets — plus, optionally, the last 10 things you copied.

## Why

Existing pie menus for macOS are either paid and closed source (Radial, PowerClick) or full automation platforms (Kando). CopyWheel is the minimal open-source alternative for the single use case of "grab a saved text without digging through your notes app".

## Features

- 🎡 Radial menu at the cursor, triggered by a global hotkey (default: <kbd>⌃⌥C</kbd>)
- 📋 Click a segment (or press <kbd>1</kbd>–<kbd>9</kbd>) → snippet lands in the clipboard
- 🕘 Clipboard history: the last 10 copied texts (also <kbd>⌘C</kbd> in other apps) as an outer ring — in memory only, never written to disk, password-manager entries are skipped. Can be turned off in the settings.
- ⌨️ Keyboard navigation: <kbd>←</kbd>/<kbd>→</kbd> rotate through a ring, <kbd>↑</kbd>/<kbd>↓</kbd> (or <kbd>Tab</kbd>) switch between snippets and history, <kbd>↩</kbd> copies
- ⚙️ Simple settings window: edit/reorder snippets, record your own hotkey, launch at login
- 🖱️ Works great with extra mouse buttons: map the button to the hotkey in Logi Options+ / your mouse driver
- 🔐 Secret snippets (tokens, passwords) are stored in the **macOS Keychain**, not on disk, and masked in the wheel
- 👋 Short tutorial on first launch, right on top of the settings (incl. "launch at login" switch)
- 🪶 Native Swift (AppKit + SwiftUI), a few hundred lines, no background bloat
- 💾 Regular snippets stored as plain JSON in `~/Library/Application Support/CopyWheel/snippets.json`

## Install

### Homebrew

```sh
brew tap weselski/tap
brew trust weselski/tap   # required once on recent Homebrew versions
brew install --cask weselski/tap/copywheel
```

Add `--no-quarantine` to the install command to skip the Gatekeeper warning for this unsigned app.

### Manual

Download `CopyWheel.dmg` from the [latest release](https://github.com/weselski/copywheel/releases/latest), open it and drag `CopyWheel.app` into `Applications`.

> [!IMPORTANT]
> **macOS will block the first launch** ("CopyWheel cannot be opened") because the app is not notarized — there's no paid Apple Developer certificate behind it. This is expected and the app is fine:
>
> 1. Try to open CopyWheel once (double-click, dismiss the warning).
> 2. Open **System Settings → Privacy & Security**, scroll down to the message about CopyWheel and click **"Open Anyway"**, then confirm.
>
> This is only needed once per installed version. Alternatively, skip the dialog entirely by removing the quarantine flag:
>
> ```sh
> xattr -dr com.apple.quarantine /Applications/CopyWheel.app
> ```
>
> (or install via Homebrew with `--no-quarantine`).

## Build & run

Requires macOS 13+ and Xcode. If `xcode-select` points to the standalone command line tools, the SwiftUI macros are missing — build with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer make run`.

```sh
make run      # builds, bundles dist/CopyWheel.app and launches it
```

Other targets: `make build` (binary only), `make bundle` (app bundle), `make clean`.

## Usage

1. Click the ◎ icon in the menu bar → **Einstellungen…** to edit your snippets and hotkey.
2. To trigger it from a mouse button, assign the same keyboard shortcut (default <kbd>⌃⌥C</kbd>) to that button in your mouse software (e.g. Logi Options+ → "Keyboard shortcut").
3. Press the hotkey anywhere → click a slice (or pick one with the arrow keys and press <kbd>↩</kbd>) → paste with <kbd>⌘V</kbd>.

Dismiss the wheel with <kbd>Esc</kbd>, by clicking the center, or by clicking anywhere else.

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — global hotkey + recorder UI

## License

MIT
