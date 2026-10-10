<p align="center">
  <img src="artifacts/plume-icon.png" alt="Plume app icon" width="120">
</p>

<h1 align="center">Plume</h1>

<p align="center">
  A sheet of glass over whatever you're doing, that you can write on.<br>
  <b>A free, open source alternative to Raycast Notes for macOS.</b>
</p>

<p align="center">
  English · <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/tiylabs/plume?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/built_with-Swift-orange?logo=swift&style=flat-square" alt="Built with Swift">
  <img src="https://img.shields.io/badge/platform-macOS_14+-lightgrey?style=flat-square" alt="Platform: macOS 14+">
  <a href="https://github.com/tiylabs/plume/releases"><img src="https://img.shields.io/github/v/release/tiylabs/plume?style=flat-square" alt="Latest release"></a>
</p>

<p align="center">
  <img src="artifacts/plume-hero.png" alt="The Plume panel floating above a code editor, showing a markdown note rendered live" width="760">
</p>

Press <kbd>⌃⌥Space</kbd> to bring a floating note over your current app, write, and dismiss it.
Unlimited notes, no account, no subscription.

## Install

```bash
brew install --cask tiylabs/tap/plume
```

Or download the `.dmg` from the [latest release](https://github.com/tiylabs/plume/releases/latest)
and drag `Plume.app` into `Applications`. Releases are signed and notarized by Apple.

## Features

- **Global hotkey.** Opens the last note, with the caret where you left it.
- **Live Markdown.** Block symbols stay hidden; inline ones show only under the caret.
- **One panel.** <kbd>⌘P</kbd> switches notes (fuzzy and full-text search), <kbd>⌘K</kbd> opens actions.
- **Plain files.** Notes are `.md` files in a folder you choose (`~/Documents/Plume` by default).
  External edits are picked up; conflicts are saved to a separate file, never overwritten.
- **Sync.** Pick iCloud Drive under Settings › Storage, or any folder your own sync tool manages.
- **Themes.** A theme is a CSS file in `~/Library/Application Support/Plume/Themes`.
- **Private.** No permissions requested, no telemetry. The only network call is an update check
  against GitHub, which can be turned off in Settings.

<kbd>⌘,</kbd> opens Settings. They are stored in `settings.json`, which Plume re-reads live.

## Build from source

Needs the Command Line Tools; no Xcode project.

```bash
make test-all  # every test suite
make dev       # rebuild and launch the isolated build/Plume Dev.app
make build     # release build of build/Plume.app
```

## License

MIT. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Forked from [ColeMei/pane](https://github.com/ColeMei/pane) (MIT) at commit `526dda4` and
developed independently since. Not affiliated with or endorsed by Raycast Technologies or the
upstream project.
