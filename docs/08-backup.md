# 08 — Backup & Restore

> Pushed from **Settings → បម្រុងទុក & ស្ដារ**.

## Purpose
Protect against device loss/damage: export all records to a JSON file (share to iCloud Drive/Files/anywhere), and restore from a chosen file.

## Wireframe
```
┌──────────────────────────────────────┐
│ ‹ ការកំណត់   បម្រុងទុក & ស្ដារ           │
│ ┌──────────────────────────────────┐ │
│ │ បម្រុងទុកទិន្នន័យទាំងអស់ជា JSON      │ │
│ │ ហើយស្ដារពេលត្រូវការ។                │ │
│ └──────────────────────────────────┘ │
│ [ ⬆️ នាំចេញ (Backup) ]                 │  → ActivityShareSheet([url])
│ [ ⬇️ ស្ដារ (Restore) ]                 │  → DocumentPicker(.json)
│ ស្ដារទិន្នន័យបានជោគជ័យ ✓               │  result message
└──────────────────────────────────────┘
```

## Service — `BackupService`
- `BackupData: Codable { transactions, activities, reminders }`.
- `exportFile()` → encodes (`.iso8601` dates, pretty + sorted keys) to `SmartFarm-Backup.json` in tmp; returns URL.
- `restore(from: URL)` → security-scoped read → decode → **upsert** each record (`delete(id:)` then `add`) so restore is idempotent; returns success Bool.

## UIKit bridges (iOS 14 safe)
- Export: `ActivityShareSheet` (`UIActivityViewController`) on the file URL (`ShareLink` is iOS 16+).
- Import: `DocumentPicker` (`UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)`); coordinator returns the picked URL, read inside a `startAccessingSecurityScopedResource()` block.

## Edge cases
- Malformed/incompatible JSON → decode fails → "ស្ដារទិន្នន័យបរាជ័យ" (no partial corruption: only valid `BackupData` mutates).
- Restore overwrites same-id records; ids not in the file are left untouched (merge, not wipe). *Future:* offer "replace all" vs "merge".
- Large backups: synchronous; acceptable for expected data sizes.

## Privacy
- 100% local. No cloud server. The user explicitly chooses where the file goes via the share sheet.

## Acceptance criteria
- [ ] Export produces a valid JSON file shareable via the system sheet.
- [ ] Restore from that file repopulates all three entity types.
- [ ] Round-trip (export → wipe via deletes → restore) yields the same records.
- [ ] Invalid file shows the failure message without crashing.
```
