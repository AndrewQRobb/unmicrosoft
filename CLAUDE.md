# Office Cleanup Scripts

macOS scripts for completely removing all traces of Microsoft Office / M365 products.

## Scripts

### remove_microsoft_office.sh
Comprehensive, interactive removal of all Microsoft Office, OneDrive, Teams, SharePoint, and M365 traces from macOS.

```bash
sudo bash remove_microsoft_office.sh [--dry-run] [--all-users]
```

**Options:**
- `--dry-run` — show what would be removed without deleting anything
- `--all-users` — clean all user accounts (default: current user only)

**Interactive prompts ask whether to keep:**
- Microsoft Edge
- Windows App (Remote Desktop)
- Microsoft AutoUpdate (MAU)
- Microsoft fonts

**What it removes (6 phases):**
1. **Processes** — kills running Microsoft processes (with confirmation)
2. **Applications** — Word, Excel, PowerPoint, Outlook, OneNote, Teams, OneDrive, SharePoint, Error Reporting (and optionally Edge, Windows App); MAU always removed (Edge/WinApp use own updaters)
3. **Per-user files** — Containers (bundle-ID + display-name), Group Containers, Application Scripts, Application Support, Preferences (incl. ByHost), Caches, Saved Application State, Logs, WebKit, HTTPStorages, Cookies, iCloud containers (Mobile Documents), CloudDocs session data, File Provider configs, Recent document lists, CloudStorage mount points, Notification icon cache, Widget archives (chronod), Daemon Container caches, Darwin temp/cache dirs (/private/var/folders), User Launch Agents, Login Items (legacy + SMAppService/BTM), Dock icons, OneDrive data folders, legacy Office dirs, TCC privacy permissions (per-bundle reset), Notification Center stale entries
4. **System files** — Launch Daemons/Agents (unloaded before removal), Privileged Helper Tools, System Application Support, System/Managed Preferences, Installer receipts, Fonts, Kernel extensions, Internet Plug-Ins, Teams Core Audio driver, Spotlight importer, Legacy receipts, Package database (pkgutil --forget), System TCC entries
5. **Discovery scan** — searches for any remaining Microsoft-related files missed by static removal, with option to remove
6. **System refresh** — resets Launch Services database, restarts Finder, Core Audio, and Notification Center daemons, resets Background Task Manager

**Cleanup approach:** Uses glob patterns (`com.microsoft.*`, `UBF8T346G9.*`) to catch items dynamically rather than relying solely on hardcoded paths. Exclusion checks honour user choices about kept apps throughout all phases.

### office_files_to_remove.txt
Snapshot of Microsoft Office-related file paths found on this Mac (Jan 2026). Historical reference only — the script now discovers paths dynamically.

## Warnings
- Requires `sudo` (root access)
- **Destructive** — permanently removes apps and data
- Use `--dry-run` first to audit what will be removed
- The discovery scan (Phase 5) may find false positives — review before confirming removal
- Close all Microsoft apps before running (script offers to kill them)
