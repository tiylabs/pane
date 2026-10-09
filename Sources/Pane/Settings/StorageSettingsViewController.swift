import AppKit
import PaneKit

/// Design frame 3a — the Storage tab.
///
/// Decision 21 is the load-bearing part: **the Sync radio picks where the vault lives, not a
/// protocol.** Off, iCloud Drive and the dimmed Peer-to-peer are all folder locations, and decision 7
/// survives intact — no server, no account, no sync code ships behind any of them. The radio exists
/// so that a future engine is one more row rather than a redesign.
///
/// Which means selecting a row has to actually move the vault, and that is the one genuinely
/// destructive thing in this window. It goes through a confirmation that names both paths and says
/// what happens to the notes, in the same posture as decision 27: at a filesystem moment, use the
/// system's own chrome and tell the truth.
@MainActor
final class StorageSettingsViewController: NSViewController {

    private let settings: SettingsStore

    /// Called when the vault location changed, so the app can re-point the watcher and the index.
    var onVaultChanged: ((URL) -> Void)?

    /// Called immediately before *Move Notes* touches a file, so the buffer can be written while it
    /// still knows where it lives. See `adopt`.
    var onWillMoveNotes: (() -> Void)?

    private var pathField: NSTextField!
    private var syncPopUp: NSPopUpButton!
    private var syncRow: SettingsRow!

    init(settings: SettingsStore) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
        title = tr("settings.tab.storage")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    /// `~/Library/Mobile Documents/com~apple~CloudDocs/Pane` — or `…/Pane-scratch` in a debug build.
    ///
    /// Built from the literal container name rather than from `url(forUbiquityContainerIdentifier:)`,
    /// which decision 13 measured returning nil here: unsigned means no ubiquity entitlement. The
    /// folder is still perfectly writable — Pane is just a non-sandboxed app writing into a synced
    /// directory, which is the whole architecture.
    ///
    /// **The folder name comes from `BuildProfile`** (decision 133). It was a literal here, so this
    /// one control reached past decision 99's separation and offered to move a scratch vault into
    /// the daily one.
    static var iCloudDriveVault: URL {
        URL(fileURLWithPath: (BuildProfile.current.iCloudVaultPath as NSString).expandingTildeInPath)
    }

    static func isInICloudDrive(_ url: URL) -> Bool {
        url.standardizedFileURL.path.contains("/Library/Mobile Documents/com~apple~CloudDocs/")
    }

    override func loadView() {
        let form = SettingsForm()
        let current = settings.value

        // ---- location ----------------------------------------------------------------------
        pathField = SettingsForm.pathField(current.vaultPath)
        let change = SettingsForm.push(tr("storage.change"), target: self, action: #selector(chooseFolder))
        let folderControl = NSStackView(views: [pathField, change])
        folderControl.orientation = .horizontal
        folderControl.spacing = 8
        // Fixed rather than a minimum: a field free to grow pushes Change… past the card edge.
        pathField.widthAnchor.constraint(equalToConstant: 200).isActive = true

        form.card([
            SettingsRow(title: tr("storage.notesFolder"), control: folderControl),
            SettingsRow(title: tr("storage.format"), control: SettingsForm.value("Markdown (.md)")),
        ])

        // ---- sync --------------------------------------------------------------------------
        // A pop-up row, not a radio group: three mutually exclusive locations is one choice, and it
        // keeps this card the same shape as every other. The dimmed third item is "coming".
        syncPopUp = SettingsForm.popUp(
            [tr("storage.sync.off"), tr("storage.sync.icloud"), tr("storage.sync.peer")],
            target: self,
            action: #selector(syncChanged)
        )
        syncPopUp.autoenablesItems = false
        syncPopUp.item(at: 2)?.isEnabled = false
        syncRow = SettingsRow(title: tr("storage.sync"), control: syncPopUp)

        // ---- recently deleted --------------------------------------------------------------
        let retention = SettingsForm.popUp(
            Settings.recentlyDeletedOptions.map { tr("storage.keepDays", ["days": String($0)]) },
            target: self,
            action: #selector(retentionChanged)
        )
        retention.selectItem(
            at: Settings.recentlyDeletedOptions.firstIndex(of: current.recentlyDeletedDays) ?? 1
        )

        form.card([
            syncRow,
            SettingsRow(title: tr("storage.recentlyDeleted"), control: retention),
        ])

        view = form.makeContentView()
        refresh(current)
    }

    func settingsChanged(_ new: Settings) {
        refresh(new)
    }

    private func refresh(_ current: Settings) {
        pathField?.stringValue = current.vaultPath
        let iCloud = Self.isInICloudDrive(current.vaultURL)
        syncPopUp?.selectItem(at: iCloud ? 1 : 0)
        // The explanation only exists while there is something to say; hidden, it takes no height.
        syncRow?.explanationLabel.stringValue = iCloud ? tr("storage.syncedNote") : ""
        syncRow?.explanationLabel.isHidden = !iCloud
    }

    // MARK: - Actions

    @objc private func retentionChanged(_ sender: NSPopUpButton) {
        let days = Settings.recentlyDeletedOptions[sender.indexOfSelectedItem]
        settings.update { $0.recentlyDeletedDays = days }
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = tr("folderPanel.prompt")
        panel.message = tr("folderPanel.message")
        panel.directoryURL = settings.value.vaultURL

        guard PanePanel.steppingAside({ panel.runModal() }) == .OK, let chosen = panel.url else { return }
        // Picking a folder by hand is a statement about where the notes already are, so nothing
        // moves — unlike the Sync radio, which is a statement about where they should be.
        adopt(chosen, movingNotes: false)
    }

    @objc private func syncChanged(_ sender: NSPopUpButton) {
        let destination = sender.indexOfSelectedItem == 1 ? Self.iCloudDriveVault
            : URL(fileURLWithPath: (Settings.defaultVaultPath as NSString).expandingTildeInPath)
        let source = settings.value.vaultURL

        guard destination.standardizedFileURL != source.standardizedFileURL else { return }

        let noteCount = (try? VaultIO.listNotes(in: source))?.count ?? 0

        // Decision 76, reaching the one modal it had not. This ran to three paragraphs, and the
        // third — "Nothing about this turns on a sync service. It only chooses which folder the
        // notes live in…" — was decision 21's *argument*, which belongs in the brief rather than in
        // front of somebody who has just clicked a radio button. The first paragraph restated the
        // title. What decision 30 actually requires is the source, the destination and the count,
        // and all three survive in one sentence each.
        let alert = NSAlert()
        alert.messageText = tr("storage.move.title", ["destination": Self.short(destination)])
        //
        // Only one of the two paths is spelled out, and it is the **source** — because that is the
        // one notes can be left behind in, and therefore the one you would have to go and find. The
        // destination is named in the title and was just chosen in a radio or an open panel. Spelled
        // out, `~/Library/Mobile Documents/com~apple~CloudDocs/Pane` took six of the alert's lines
        // on its own, which is most of what "too much to read" meant.
        alert.informativeText = noteCount == 0
            ? tr("storage.move.none", ["path": Self.tilde(destination)])
            : L10n.plural(
                "storage.move.some",
                count: noteCount,
                ["destination": Self.short(destination), "source": Self.tilde(source)]
            )
        alert.alertStyle = .informational
        if noteCount > 0 { alert.addButton(withTitle: tr("storage.move.move")) }
        // "Just Point There" was jargon for a thing the user was not thinking about — pointing. The
        // question on screen is what happens to the *notes*, so both answers are verbs about the
        // notes and the pair reads as one choice.
        alert.addButton(withTitle: noteCount > 0 ? tr("storage.move.leave") : tr("common.continue"))
        alert.addButton(withTitle: tr("common.cancel"))

        let response = PanePanel.steppingAside { alert.runModal() }
        let cancel: NSApplication.ModalResponse = noteCount > 0 ? .alertThirdButtonReturn : .alertSecondButtonReturn
        guard response != cancel else {
            refresh(settings.value)  // put the pop-up back where it was
            return
        }

        adopt(destination, movingNotes: noteCount > 0 && response == .alertFirstButtonReturn)
    }

    // MARK: - Moving

    private func adopt(_ destination: URL, movingNotes: Bool) {
        do {
            try FileManager.default.createDirectory(
                at: destination, withIntermediateDirectories: true
            )
            if movingNotes {
                // Decision 56, reached from the one direction its amendment missed.
                //
                // The flush that protects this path is the one `settings.update` below triggers —
                // and it runs *after* the files have already moved, so it writes to the old vault
                // under a name that is no longer there, `VaultIO.write` reads that as "missing" and
                // recreates it, and you are left with a resurrected copy in the old folder holding
                // your newest text while the moved copy is stale.
                //
                // Flushing first is not quite the whole fix, and the gap survived a release
                // (decision 140): `flush` *enqueues* on the vault queue and returns, and the loop
                // below is `FileManager` on this thread, so the move overtook the write it was
                // meant to wait for and the fault above happened anyway. `onWillMoveNotes` drains
                // the queue as well as flushing it, which is what makes "first" true.
                onWillMoveNotes?()
                try moveNotes(from: settings.value.vaultURL, to: destination)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = tr("storage.useFailed")
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            _ = PanePanel.steppingAside { alert.runModal() }
            refresh(settings.value)
            return
        }

        settings.update { $0.vaultPath = Self.tildified(destination) }
        onVaultChanged?(destination)
        refresh(settings.value)
    }

    /// Moves every `.md` file across, and stops at the first failure rather than continuing.
    ///
    /// A half-moved vault is recoverable — both folders are right there and every note is a plain
    /// file — but only if the move stops and says so. Carrying on past an error would scatter the
    /// notes across two folders and report success.
    private func moveNotes(from source: URL, to destination: URL) throws {
        for note in try VaultIO.listNotes(in: source) {
            let target = destination.appendingPathComponent(note.lastPathComponent)
            guard !FileManager.default.fileExists(atPath: target.path) else {
                // Same filename on both sides. Frozen filenames (decision 2) make this a genuine
                // collision rather than a coincidence, so leave both alone and let the user look.
                continue
            }
            try FileManager.default.moveItem(at: note, to: target)
        }
    }

    private static func tildified(_ url: URL) -> String {
        let home = NSHomeDirectory()
        let path = url.standardizedFileURL.path
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }

    private static func short(_ url: URL) -> String {
        isInICloudDrive(url) ? tr("storage.sync.icloud") : url.lastPathComponent
    }

    /// A path a person can read in a sentence. `/Users/colemei/Pane` is four words of noise before
    /// the one that matters.
    private static func tilde(_ url: URL) -> String {
        (url.path as NSString).abbreviatingWithTildeInPath
    }
}
