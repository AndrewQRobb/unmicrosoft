# unmicrosoft

Complete removal of Microsoft Office / M365 from macOS. Like they were never installed.

One interactive script that removes **all** traces — apps, containers, preferences, caches, launch agents, login items, Dock icons, iCloud sync data, TCC permissions, Notification Center entries, Spotlight importers, audio drivers, temp caches, and more. Includes a discovery scan to catch anything missed.

## Quick start

```bash
# Preview what would be removed (nothing is deleted)
sudo bash unmicrosoft.sh --dry-run

# Run for real
sudo bash unmicrosoft.sh

# Clean all user accounts
sudo bash unmicrosoft.sh --all-users
```

## What it removes

| Phase | What |
|-------|------|
| 1. Processes | Kills running Microsoft processes (with confirmation) |
| 2. Applications | Word, Excel, PowerPoint, Outlook, OneNote, Teams, OneDrive, SharePoint, Error Reporting, AutoUpdate |
| 3. Per-user files | Containers, Group Containers, Application Scripts, Application Support, Preferences (incl. ByHost), Caches, Saved Application State, Logs, WebKit, HTTPStorages, Cookies, iCloud containers, CloudDocs session data, File Provider configs, Recent document lists, CloudStorage mount points, Notification icon cache, Widget archives, Daemon Container caches, temp caches (`/private/var/folders`), User Launch Agents, Login Items (legacy + SMAppService/BTM), Dock icons, OneDrive data folders, TCC privacy permissions, Notification Center stale entries |
| 4. System files | Launch Daemons/Agents, Privileged Helper Tools, System Application Support, System/Managed Preferences, Installer receipts, Fonts, Kernel extensions, Internet Plug-Ins, Teams Core Audio driver, Spotlight importer, Package database (`pkgutil --forget`), System TCC entries |
| 5. Discovery scan | `find`-based sweep for anything the static phases missed |
| 6. System refresh | Rebuilds Launch Services database, restarts Finder, Core Audio, and Notification Center |

## Interactive prompts

The script asks what to **keep**:

- **Microsoft Edge** — uses its own `EdgeUpdater`, does not need MAU
- **Windows App (Remote Desktop)** — independent of Office, does not need MAU
- **Microsoft fonts** — Calibri, Cambria, Consolas, etc. in `/Library/Fonts`

AutoUpdate (MAU) is always removed since neither Edge nor Windows App uses it.

## Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Show what would be removed without deleting anything |
| `--all-users` | Clean all user accounts (default: current user only) |
| `--help` | Show usage |

## Requirements

- macOS (tested on Tahoe 26.x)
- `sudo` access
- Close all Microsoft apps before running (or let the script kill them)

## After running

1. Open **Keychain Access** and search for `Microsoft` — delete any remaining entries
2. **Empty Trash**
3. **Restart your Mac** to finalize BTM/startup item cleanup and clear caches

## What it keeps (by default)

- Microsoft Edge and its `EdgeUpdater` infrastructure
- Windows App (Remote Desktop)
- Your personal documents — the script never touches `~/Documents`

## Reference

`office_files_to_remove.txt` is a historical snapshot of Microsoft file paths found on a specific Mac (Jan 2026). The script now discovers paths dynamically via glob patterns and `find`.
