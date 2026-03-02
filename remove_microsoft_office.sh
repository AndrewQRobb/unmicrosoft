#!/bin/bash
# =============================================================
# Microsoft Office / OneDrive / Teams Cleanup Script
# Generated: 2026-02-23
# EXCLUDES: Microsoft Edge, Windows App (Remote Desktop), AutoUpdate (MAU)
# =============================================================
# Run with: sudo bash ~/Desktop/remove_microsoft_office.sh
# =============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

USER_HOME="/Users/andrewrobb"
REMOVED=0
SKIPPED=0
FAILED=0

remove_item() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        if rm -rf "$path" 2>/dev/null; then
            echo -e "  ${GREEN}[REMOVED]${NC} $path"
            ((REMOVED++))
        else
            echo -e "  ${RED}[FAILED]${NC} $path (permission denied?)"
            ((FAILED++))
        fi
    else
        echo -e "  ${YELLOW}[SKIP]${NC}    $path (not found)"
        ((SKIPPED++))
    fi
}

echo "============================================================="
echo " Microsoft Office / OneDrive / Teams Cleanup"
echo " Excluding: Edge, Windows App, AutoUpdate (MAU)"
echo "============================================================="
echo ""

# --- Check for running Microsoft processes (excluding Edge & RDP) ---
echo "Checking for running Microsoft processes..."
MSFT_PROCS=$(pgrep -afl "Microsoft|OneDrive|Teams" 2>/dev/null | grep -vi "Edge\|Remote Desktop\|rdc\|Windows App\|AutoUpdate\|MAU" || true)
if [ -n "$MSFT_PROCS" ]; then
    echo -e "${RED}WARNING: Microsoft processes are still running:${NC}"
    echo "$MSFT_PROCS"
    echo ""
    read -p "Kill these processes and continue? (y/N): " KILL_PROCS
    if [[ "$KILL_PROCS" =~ ^[Yy]$ ]]; then
        echo "$MSFT_PROCS" | awk '{print $1}' | xargs kill -9 2>/dev/null || true
        sleep 2
        echo "Processes killed."
    else
        echo "Exiting. Close Microsoft apps first, then re-run."
        exit 1
    fi
fi

echo ""
echo "--- 1. APPLICATION ---"
remove_item "/Applications/OneDrive.app"

echo ""
echo "--- 2. USER LIBRARY - CONTAINERS ---"
remove_item "$USER_HOME/Library/Containers/com.microsoft.OneDriveLauncher"
remove_item "$USER_HOME/Library/Containers/com.microsoft.OneDrive.FinderSync"
remove_item "$USER_HOME/Library/Containers/com.microsoft.OneDrive.FileProvider"
remove_item "$USER_HOME/Library/Containers/com.microsoft.Outlook.CalendarWidget"
remove_item "$USER_HOME/Library/Containers/com.microsoft.Excel.widgetextension"
remove_item "$USER_HOME/Library/Containers/com.microsoft.Powerpoint.widgetextension"
remove_item "$USER_HOME/Library/Containers/com.microsoft.Word.widgetextension"
remove_item "$USER_HOME/Library/Containers/com.microsoft.Microsoft-Mashup-Container"
remove_item "$USER_HOME/Library/Containers/com.microsoft.pasteboard-xpc"

echo ""
echo "--- 3. USER LIBRARY - GROUP CONTAINERS ---"
remove_item "$USER_HOME/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite"

echo ""
echo "--- 4. USER LIBRARY - APPLICATION SUPPORT ---"
# Selectively clean ~/Library/Application Support/Microsoft/
# (keeping EdgeUpdater which is needed by Microsoft Edge)
remove_item "$USER_HOME/Library/Application Support/Microsoft/Teams"
remove_item "$USER_HOME/Library/Application Support/Microsoft/vcxpc"
remove_item "$USER_HOME/Library/Application Support/OneDrive"
remove_item "$USER_HOME/Library/Application Support/com.microsoft.SharePoint-mac"
remove_item "$USER_HOME/Library/Application Support/com.microsoft.OneDrive"

echo ""
echo "--- 5. USER LIBRARY - PREFERENCES ---"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.SharePoint-mac.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.OneDrive.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.OneDriveStandaloneUpdater.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.office.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.shared.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.OneDriveUpdater.plist"
remove_item "$USER_HOME/Library/Preferences/com.microsoft.teams2.helper.plist"

echo ""
echo "--- 6. USER LIBRARY - CACHES ---"
remove_item "$USER_HOME/Library/Caches/OneDrive"
remove_item "$USER_HOME/Library/Caches/com.microsoft.SharePoint-mac"
remove_item "$USER_HOME/Library/Caches/com.microsoft.OneDriveStandaloneUpdater"
remove_item "$USER_HOME/Library/Caches/com.microsoft.OneDrive"
remove_item "$USER_HOME/Library/Caches/com.microsoft.SyncReporter"
remove_item "$USER_HOME/Library/Caches/com.microsoft.OneDriveUpdater"

echo ""
echo "--- 7. USER LIBRARY - LOGS ---"
remove_item "$USER_HOME/Library/Logs/Microsoft Teams Helper (Renderer)"

echo ""
echo "--- 8. USER LIBRARY - WEBKIT ---"
remove_item "$USER_HOME/Library/WebKit/com.microsoft.OneDrive"

echo ""
echo "--- 9. USER LIBRARY - HTTP STORAGES ---"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDrive"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDrive.binarycookies"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater.binarycookies"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDriveUpdater"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.OneDriveUpdater.binarycookies"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.SharePoint-mac"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.SharePoint-mac.binarycookies"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.SyncReporter"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.SyncReporter.binarycookies"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.teams"
remove_item "$USER_HOME/Library/HTTPStorages/com.microsoft.teams.binarycookies"

echo ""
echo "--- 10. SYSTEM - LAUNCH DAEMONS (requires sudo) ---"
remove_item "/Library/LaunchDaemons/com.microsoft.OneDriveStandaloneUpdaterDaemon.plist"
remove_item "/Library/LaunchDaemons/com.microsoft.teams.TeamsUpdaterDaemon.plist"
remove_item "/Library/LaunchDaemons/com.microsoft.OneDriveUpdaterDaemon.plist"
remove_item "/Library/LaunchDaemons/com.microsoft.office.licensingV2.helper.plist"
# KEPT: com.microsoft.autoupdate.helper.plist (needed by Edge/Windows App)

echo ""
echo "--- 11. SYSTEM - LAUNCH AGENTS (requires sudo) ---"
remove_item "/Library/LaunchAgents/com.microsoft.SyncReporter.plist"
remove_item "/Library/LaunchAgents/com.microsoft.OneDriveStandaloneUpdater.plist"
# KEPT: com.microsoft.update.agent.plist (needed by Edge/Windows App)

echo ""
echo "--- 12. SYSTEM - PRIVILEGED HELPER TOOLS (requires sudo) ---"
# KEPT: com.microsoft.autoupdate.helper (needed by Edge/Windows App)
remove_item "/Library/PrivilegedHelperTools/com.microsoft.office.licensingV2.helper"

echo ""
echo "--- 13. SYSTEM - APPLICATION SUPPORT (requires sudo) ---"
# KEPT: /Library/Application Support/Microsoft/MAU2.0 (needed by Edge/Windows App)

echo ""
echo "--- 14. SYSTEM - PREFERENCES (requires sudo) ---"
# KEPT: /Library/Preferences/com.microsoft.autoupdate2.plist (needed by MAU)
remove_item "/Library/Preferences/com.microsoft.teams.plist"

echo ""
echo "--- 15. INSTALLER RECEIPTS (requires sudo) ---"
remove_item "/var/db/receipts/com.microsoft.MSTeamsAudioDevice.bom"
remove_item "/var/db/receipts/com.microsoft.MSTeamsAudioDevice.plist"
remove_item "/var/db/receipts/com.microsoft.OneDrive.bom"
remove_item "/var/db/receipts/com.microsoft.OneDrive.plist"
remove_item "/var/db/receipts/com.microsoft.onenote.mac.bom"
remove_item "/var/db/receipts/com.microsoft.onenote.mac.plist"
remove_item "/var/db/receipts/com.microsoft.package.DFonts.bom"
remove_item "/var/db/receipts/com.microsoft.package.DFonts.plist"
remove_item "/var/db/receipts/com.microsoft.package.Frameworks.bom"
remove_item "/var/db/receipts/com.microsoft.package.Frameworks.plist"
# KEPT: com.microsoft.package.Microsoft_AutoUpdate.app receipts (needed by MAU)
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Excel.app.bom"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Excel.app.plist"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_OneNote.app.bom"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_OneNote.app.plist"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Outlook.app.bom"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Outlook.app.plist"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_PowerPoint.app.bom"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_PowerPoint.app.plist"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Word.app.bom"
remove_item "/var/db/receipts/com.microsoft.package.Microsoft_Word.app.plist"
remove_item "/var/db/receipts/com.microsoft.package.Proofing_Tools.bom"
remove_item "/var/db/receipts/com.microsoft.package.Proofing_Tools.plist"
remove_item "/var/db/receipts/com.microsoft.pkg.licensing.bom"
remove_item "/var/db/receipts/com.microsoft.pkg.licensing.plist"
remove_item "/var/db/receipts/com.microsoft.teams.bom"
remove_item "/var/db/receipts/com.microsoft.teams.plist"
remove_item "/var/db/receipts/com.microsoft.teams2.bom"
remove_item "/var/db/receipts/com.microsoft.teams2.plist"

echo ""
echo "--- 16. ONEDRIVE DATA FOLDER ---"
if [ -d "$USER_HOME/OneDrive" ]; then
    ONEDRIVE_COUNT=$(find "$USER_HOME/OneDrive" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ONEDRIVE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}WARNING: ~/OneDrive contains $ONEDRIVE_COUNT file(s).${NC}"
        read -p "  Delete ~/OneDrive and all contents? (y/N): " DEL_OD
        if [[ "$DEL_OD" =~ ^[Yy]$ ]]; then
            remove_item "$USER_HOME/OneDrive"
        else
            echo -e "  ${YELLOW}[SKIP]${NC}    ~/OneDrive (user chose to keep)"
            ((SKIPPED++))
        fi
    else
        remove_item "$USER_HOME/OneDrive"
    fi
else
    echo -e "  ${YELLOW}[SKIP]${NC}    ~/OneDrive (not found)"
    ((SKIPPED++))
fi

echo ""
echo "============================================================="
echo " CLEANUP COMPLETE"
echo "============================================================="
echo -e " ${GREEN}Removed:${NC} $REMOVED items"
echo -e " ${YELLOW}Skipped:${NC} $SKIPPED items (not found or kept)"
echo -e " ${RED}Failed:${NC}  $FAILED items (check permissions)"
echo ""
echo " MANUAL STEPS REMAINING:"
echo "  1. Open Keychain Access, search 'Microsoft', delete all entries"
echo "  2. Empty Trash"
echo "  3. Restart your Mac"
echo "============================================================="
