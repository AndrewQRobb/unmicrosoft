# Office Cleanup Scripts

macOS scripts for completely removing Microsoft Office, OneDrive, and Teams while preserving Edge, Windows App (Remote Desktop), and AutoUpdate (MAU).

## Scripts

### remove_microsoft_office.sh
Removes all Microsoft Office apps, OneDrive, Teams, and their associated files (preferences, caches, containers, launch agents, etc.).

```bash
sudo bash remove_microsoft_office.sh
```

**What it does:**
- Checks for running Microsoft processes and prompts to quit them
- Removes Office apps (Word, Excel, PowerPoint, Outlook, OneNote)
- Removes OneDrive and Teams
- Cleans up preferences, caches, containers, launch agents/daemons
- Provides a summary of removed/skipped/failed items
- Suggests reboot after completion

**Excludes:** Microsoft Edge, Windows App (Remote Desktop), AutoUpdate (MAU)

### office_files_to_remove.txt
Reference list of all Microsoft Office-related file paths on macOS. Used as a reference for the cleanup script.

## Warnings
- Requires `sudo` (root access)
- **Destructive** - permanently removes apps and data
- Hardcoded to `/Users/andrewrobb` - update `USER_HOME` variable if running on a different account
- Close all Microsoft apps before running
