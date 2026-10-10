<p align="center">
  <img src="artifacts/plume-icon.png" alt="Plume app icon" width="120">
</p>

<h1 align="center">Plume</h1>

<p align="center">
  A sheet of glass over whatever you're doing, that you can write on.
</p>

<p align="center">
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

Press <kbd>⌃⌥Space</kbd> to bring a floating note over your current app and continue where you
left off. Write with live Markdown formatting, switch notes with <kbd>⌘P</kbd>, and dismiss the
panel when you're done. Plume runs independently of Raycast, with unlimited notes and no account
or subscription.

<p align="center">
  <a href="https://github.com/tiylabs/plume/releases/latest"><b>Download for macOS</b></a>
  · <a href="#install">Installation instructions</a>
</p>

## Install

```bash
brew install --cask tiylabs/tap/plume
```

Or download the `.dmg` from the [latest release](https://github.com/tiylabs/plume/releases/latest), open it,
and drag `Plume.app` onto the `Applications` folder beside it.

Releases are signed with an Apple Developer ID and notarized by Apple, so Plume opens normally on first launch.

## Coming from Raycast Notes

Plume is built around familiar Raycast Notes habits: summon a floating note, start typing, and use
keyboard shortcuts to switch notes and run actions. It is a standalone app, so Raycast is not required.

|                | Raycast Notes                    | Plume                                                     |
| -------------- | -------------------------------- | -------------------------------------------------------- |
| Notes          | 5 on the free plan, unlimited on Pro | Unlimited                                              |
| Where they live| Raycast's own storage            | `.md` files in a folder you pick                          |
| Sync           | Cloud Sync, on Pro               | Sync the notes folder between Macs with iCloud Drive or a tool such as Syncthing |
| Cost           | Free tier + Pro subscription     | Free, MIT, no account                                     |
| App            | Part of Raycast                  | Standalone macOS app; no Raycast required                 |

Plume does not provide its own cloud service or an iPhone or iPad app. Folder sync carries your
notes between Macs; local settings and window state stay on each Mac.

Raycast plan details: [pricing](https://www.raycast.com/pricing) and
[Raycast Notes](https://www.raycast.com/core-features/notes), checked October 9, 2026.

*Not affiliated with or endorsed by Raycast Technologies.*

## What it does

<p align="center">
  <img src="artifacts/plume-switcher.png" alt="The note switcher, showing notes grouped into recency bands" width="46%">
  <img src="artifacts/plume-actions.png" alt="The action panel, listing actions with their keyboard shortcuts" width="46%">
</p>

- **Pick up where you left off.** Summon the panel over your current app with a global hotkey.
  Plume remembers your last note and each note's caret position.
- **Write with structure.** Markdown renders as you type. Headings, lists, quotes and code blocks
  never show their symbols, and bold, links and other inline styles show theirs only under the caret.
- **Stay in one panel.** <kbd>⌘P</kbd> switches notes with recency groups, fuzzy title matching and
  full text search. No results? <kbd>⏎</kbd> creates a note with your query as its title.
  <kbd>⌘K</kbd> brings up actions for find, export, reveal in Finder, file renaming, screen capture
  privacy and recently deleted notes.
- **A window that follows your writing.** Height grows with the note until you resize it manually.
  Float over fullscreen apps, follow Spaces, and choose light or dark appearance.
- **Fits your routine.** Access Plume from the menu bar or launch it at login.
- External edits are picked up automatically. If a file changes before Plume saves, it preserves
  the pending edit in a separate conflict file instead of silently overwriting the external change.
- **Deleted notes are recoverable** for as long as you choose, and they wait outside your vault so
  they don't sync back.

## Your notes

Notes are plain Markdown files in a folder you choose, `~/Documents/Plume` by default, with no
added frontmatter or notes database. A note's title is its first line. You can edit the files in
other apps, and Plume picks up those changes automatically.

Caret positions, pins and window geometry live in `~/Library/Application Support/Plume/`, outside
the vault, never synced.

<details>
<summary>File naming and sync details</summary>

While a new note is open, its filename follows the title, for example
`2026-08-11-1453-first-few-words.md`. Once you leave the note, automatic renaming stops; the
timestamp stays fixed. This limits filename changes that sync tools need to reconcile.
Use **Rename File…** in <kbd>⌘K</kbd> whenever you want to rename it yourself.

To sync notes between Macs, pick **iCloud Drive** under Settings › Storage (recommended), or
choose a folder your own sync tool manages. Plume reads and writes the files; the sync tool
carries them between Macs. Plume normalizes trailing newlines when saving, so files are not
guaranteed to be byte identical to text entered or edited elsewhere.

</details>

## Settings

<p align="center">
  <img src="artifacts/plume-settings.png" alt="The Appearance tab of the Settings window" width="46%">
  <img src="artifacts/plume-dark.png" alt="The same note in dark mode" width="46%">
</p>

<kbd>⌘,</kbd> from any panel. Hotkey recorder, notes folder and iCloud sync, how the switcher sorts
notes, accent, text size, translucency, and shortcut recorders for navigation and panel actions.
Additional editor shortcut overrides are available in `settings.json`.

It's all plain JSON in `settings.json`, which Plume watches and re-reads live — so editing it by
hand, over SSH, or from a dotfiles repo works immediately.

## Themes

A **theme is just a CSS file**. Drop one in `~/Library/Application Support/Plume/Themes` and it
appears in the Appearance tab. A few of Plume's own variables cover most of what people want to
change, so a usable theme can be four lines:

```css
:root {
  --font-ui: "iA Writer Quattro", Georgia, serif;  /* the note's text */
  --font-mono: "JetBrains Mono", monospace;        /* code and fences */
  --text-size: 16px;                               /* also on ⌘= / ⌘− / ⌘0 */
  --accent: #4a7fb5;                               /* markers, links, the caret */
}
```

Anything else in the file is ordinary CSS against the editor's own classes, and it wins — a theme's
`body` rule overrides Plume's. Themes live outside your notes folder, so they never sync with it.

## Privacy

Plume requests **no privacy permissions at all** — the global hotkey needs no Accessibility access.
No telemetry, no account, no server. The only network call it ever makes is asking GitHub whether
a newer release exists — when you press the button under Settings → About, and once a day when you
summon the panel, so you find out that something you reported has been fixed. It never downloads,
installs or opens anything, and nothing about you or your machine is sent. Turn the daily one off
with **Check for updates** in Settings → General; the button still works.

## Build from source

A SwiftPM package plus a web bundle. No Xcode project, on purpose — everything builds with the
Command Line Tools alone.

```bash
Scripts/test-all.sh            # every test suite, against one bundle build
make dev                      # rebuild and launch the isolated build/Plume Dev.app
Scripts/build-app.sh --release # assemble the release build/Plume.app
```

Swift + AppKit owns the panel, hotkey and file I/O; the editor is CodeMirror 6 in a `WKWebView`.
No Node process, no Rust core, no Electron. The buffer *is* the Markdown source. Live preview
changes its presentation without converting notes to a separate rich text format.

## License

MIT. See [LICENSE](LICENSE). Third-party components bundled in the app are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This project is a fork of [ColeMei/pane](https://github.com/ColeMei/pane) by Cole Mei, which is
also MIT licensed. It was forked from upstream commit `526dda4` and has been developed independently
since, and was renamed from Pane to Plume. It is not affiliated with or endorsed by the upstream project or its author.

## Acknowledgement

Special thanks to [linux.do](https://linux.do)
