# CopyWheel

<p align="center">
  <img src="docs/demo.gif" width="360" alt="CopyWheel demo: a radial menu appears at the cursor, hovering highlights segments, clicking copies the snippet" />
</p>

A tiny, native macOS menu bar app that does exactly one thing: press a hotkey and a **radial menu appears at your mouse cursor** — click a segment and that snippet is **copied to your clipboard**.

No Electron, no clipboard history, no automation platform. Just a wheel of your snippets.

## Why

Existing pie menus for macOS are either paid and closed source (Radial, PowerClick) or full automation platforms (Kando). CopyWheel is the minimal open-source alternative for the single use case of "grab a saved text without digging through your notes app".

## Features

- 🎡 Radial menu at the cursor, triggered by a global hotkey (default: <kbd>⌃⌥C</kbd>)
- 📋 Click a segment (or press <kbd>1</kbd>–<kbd>9</kbd>) → snippet lands in the clipboard
- ⚙️ Simple settings window: edit/reorder snippets, record your own hotkey, launch at login
- 🖱️ Works great with extra mouse buttons: map the button to the hotkey in Logi Options+ / your mouse driver
- 🔐 Secret snippets (tokens, passwords) are stored in the **macOS Keychain**, not on disk, and masked in the wheel
- 👋 First-launch onboarding with common presets (email, phone, address, token, password)
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

The app is ad-hoc signed (no Apple Developer certificate), so on first launch macOS will warn you. Either right-click the app → **Open**, or remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/CopyWheel.app
```

## Build & run

Requires macOS 13+ and Xcode command line tools.

```sh
make run      # builds, bundles dist/CopyWheel.app and launches it
```

Other targets: `make build` (binary only), `make bundle` (app bundle), `make clean`.

## Usage

1. Click the ◎ icon in the menu bar → **Einstellungen…** to edit your snippets and hotkey.
2. To trigger it from a mouse button, assign the same keyboard shortcut (default <kbd>⌃⌥C</kbd>) to that button in your mouse software (e.g. Logi Options+ → "Keyboard shortcut").
3. Press the hotkey anywhere → click a slice → paste with <kbd>⌘V</kbd>.

Dismiss the wheel with <kbd>Esc</kbd>, by clicking the center, or by clicking anywhere else.

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — global hotkey + recorder UI

## License

MIT
