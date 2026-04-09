#!/bin/bash
# ==============================================================================
# Microsoft Office / M365 Complete Removal Script for macOS
#
# Removes all traces of Microsoft Office, OneDrive, Teams, SharePoint, and
# related M365 products. Interactive prompts let you keep Edge and/or
# Windows App. AutoUpdate (MAU) is always removed — Edge and Windows App
# use their own updaters.
#
# Usage: sudo bash remove_microsoft_office.sh [--dry-run] [--all-users]
# ==============================================================================

set -uo pipefail

# --- Colors ---------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Counters & flags -----------------------------------------------------
REMOVED=0
SKIPPED=0
FAILED=0

DRY_RUN=false
ALL_USERS=false
KEEP_EDGE=true
KEEP_WINAPP=true
KEEP_MAU=false
REMOVE_FONTS=false

# --- Parse arguments ------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --all-users) ALL_USERS=true ;;
        --help|-h)
            echo "Usage: sudo bash $0 [--dry-run] [--all-users]"
            echo ""
            echo "  --dry-run     Show what would be removed without deleting"
            echo "  --all-users   Clean all user accounts (default: current user)"
            exit 0
            ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# ==============================================================================
# Helper functions
# ==============================================================================

section() { echo ""; echo -e "${BOLD}--- $1 ---${NC}"; }

prompt_yn() {
    local prompt="$1" default="${2:-n}" response
    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n]: " response
        [[ ! "$response" =~ ^[Nn]$ ]]
    else
        read -r -p "$prompt [y/N]: " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

is_excluded() {
    local name
    name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    $KEEP_EDGE   && [[ "$name" == *"edge"* ]]                                                          && return 0
    $KEEP_WINAPP && [[ "$name" == *"remote desktop"* || "$name" == *"rdc"* || "$name" == *"windows app"* ]] && return 0
    $KEEP_MAU    && [[ "$name" == *"autoupdate"* || "$name" == *"mau"* ]]                               && return 0
    return 1
}

remove_item() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        if $DRY_RUN; then
            echo -e "  ${CYAN}[DRY RUN]${NC} Would remove: $path"
            REMOVED=$((REMOVED + 1))
        elif rm -rf "$path" 2>/dev/null; then
            echo -e "  ${GREEN}[REMOVED]${NC} $path"
            REMOVED=$((REMOVED + 1))
        else
            echo -e "  ${RED}[FAILED]${NC}  $path"
            FAILED=$((FAILED + 1))
        fi
    fi
}

# Remove every item in $dir matching $pattern, honouring exclusions.
remove_matching() {
    local dir="$1" pattern="$2"
    for item in "$dir"/$pattern; do
        [ -e "$item" ] || [ -L "$item" ] || continue
        is_excluded "$(basename "$item")" && continue
        remove_item "$item"
    done
}

# Unload a launchd plist, then delete it.
unload_and_remove() {
    local plist="$1" domain="${2:-system}"
    if [ -f "$plist" ]; then
        if ! $DRY_RUN; then
            launchctl bootout "$domain" "$plist" 2>/dev/null || true
        fi
        remove_item "$plist"
    fi
}

# ==============================================================================
# Preflight
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run with sudo.${NC}"
    echo "Usage: sudo bash $0 [--dry-run] [--all-users]"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || stat -f '%Su' /dev/console 2>/dev/null || echo '')}"
if [[ -z "$REAL_USER" ]]; then
    echo -e "${RED}Error: Cannot determine the invoking user. Run with sudo (not as root directly).${NC}"
    exit 1
fi

# ==============================================================================
# Banner
# ==============================================================================
echo "============================================================="
echo " Microsoft Office / M365 Complete Removal Tool for macOS"
$DRY_RUN && echo -e " ${CYAN}*** DRY RUN — nothing will be deleted ***${NC}"
echo "============================================================="

# ==============================================================================
# Interactive prompts
# ==============================================================================
section "Configuration"
echo "Which Microsoft products do you want to KEEP?"
echo ""

if prompt_yn "  Keep Microsoft Edge?"; then
    KEEP_EDGE=true;  echo -e "    ${GREEN}-> Keeping Edge${NC}"
else
    KEEP_EDGE=false;  echo -e "    ${YELLOW}-> Will remove Edge${NC}"
fi

if prompt_yn "  Keep Windows App (Remote Desktop)?"; then
    KEEP_WINAPP=true;  echo -e "    ${GREEN}-> Keeping Windows App${NC}"
else
    KEEP_WINAPP=false;  echo -e "    ${YELLOW}-> Will remove Windows App${NC}"
fi

# MAU is always removed — Edge uses its own EdgeUpdater and Windows App
# does not use MAU at all.
KEEP_MAU=false
echo -e "    ${DIM}  AutoUpdate (MAU) will be removed (not used by Edge or Windows App)${NC}"

echo ""
if prompt_yn "  Remove Microsoft fonts from /Library/Fonts?"; then
    REMOVE_FONTS=true;  echo -e "    ${YELLOW}-> Will remove Microsoft fonts${NC}"
else
    REMOVE_FONTS=false;  echo -e "    ${GREEN}-> Keeping Microsoft fonts${NC}"
fi

# --- Target users ---------------------------------------------------------
declare -a TARGET_USERS=()
if $ALL_USERS; then
    for uhome in /Users/*/Library; do
        u=$(basename "$(dirname "$uhome")")
        [[ "$u" == "Shared" || "$u" == ".localized" || "$u" == "Guest" ]] && continue
        TARGET_USERS+=("$u")
    done
else
    TARGET_USERS+=("$REAL_USER")
fi

echo ""
echo -e "Target user(s): ${BOLD}${TARGET_USERS[*]}${NC}"
if ! $ALL_USERS; then
    other_count=$(ls /Users/ 2>/dev/null | grep -cv -e "^${REAL_USER}$" -e '^Shared$' -e '^\.localized$' -e '^Guest$' -e '^\.$' -e '^\.\.$' || true)
    [[ "$other_count" -gt 0 ]] && echo -e "${DIM}  (use --all-users to clean all accounts)${NC}"
fi

# --- Final confirmation ---------------------------------------------------
echo ""
echo "============================================================="
echo " Ready to clean Microsoft Office / M365"
$DRY_RUN && echo -e " ${CYAN}DRY RUN — no files will be deleted${NC}"
echo "============================================================="
if ! $DRY_RUN; then
    prompt_yn "Proceed?" || { echo "Aborted."; exit 0; }
fi

# ==============================================================================
# Phase 1 — Kill running Microsoft processes
# ==============================================================================
section "Phase 1: Stopping Microsoft processes"

PROC_EXCLUDE="XXXXXXXXXXXXXXXX"  # dummy that never matches
$KEEP_EDGE   && PROC_EXCLUDE="${PROC_EXCLUDE}\\|Edge"
$KEEP_WINAPP && PROC_EXCLUDE="${PROC_EXCLUDE}\\|Remote Desktop\\|rdc\\|Windows App"
$KEEP_MAU    && PROC_EXCLUDE="${PROC_EXCLUDE}\\|AutoUpdate\\|MAU"

MSFT_PROCS=$(pgrep -afl "Microsoft|OneDrive|Teams|SharePoint" 2>/dev/null \
    | grep -vi "$PROC_EXCLUDE" || true)

if [ -n "$MSFT_PROCS" ]; then
    echo -e "${YELLOW}Running Microsoft processes:${NC}"
    echo "$MSFT_PROCS"
    echo ""
    if $DRY_RUN; then
        echo -e "  ${CYAN}[DRY RUN]${NC} Would kill these processes"
    elif prompt_yn "  Kill these processes?"; then
        echo "$MSFT_PROCS" | awk '{print $1}' | xargs kill -9 2>/dev/null || true
        sleep 2
        echo -e "  ${GREEN}Processes terminated.${NC}"
    else
        echo -e "  ${YELLOW}Warning: running processes may block removal.${NC}"
    fi
else
    echo "  No relevant Microsoft processes running."
fi

# ==============================================================================
# Phase 2 — Remove applications
# ==============================================================================
section "Phase 2: Applications"

APPS=(
    "Microsoft Word.app"
    "Microsoft Excel.app"
    "Microsoft PowerPoint.app"
    "Microsoft Outlook.app"
    "Microsoft OneNote.app"
    "Microsoft Teams.app"
    "Microsoft Teams (work or school).app"
    "Microsoft Teams classic.app"
    "OneDrive.app"
    "Microsoft SharePoint.app"
)
$KEEP_EDGE   || APPS+=("Microsoft Edge.app")
$KEEP_WINAPP || APPS+=("Windows App.app" "Microsoft Remote Desktop.app")
$KEEP_MAU    || APPS+=("Microsoft AutoUpdate.app")

for app in "${APPS[@]}"; do
    remove_item "/Applications/$app"
done
$KEEP_MAU || remove_item "/Applications/Utilities/Microsoft AutoUpdate.app"

# ==============================================================================
# Phase 3 — Per-user cleanup
# ==============================================================================
clean_user() {
    local user="$1"
    local home="/Users/$user"
    local uid
    uid=$(id -u "$user" 2>/dev/null || echo "")

    [ -d "$home/Library" ] || { echo "  Skipping $user (no Library)"; return; }

    section "Phase 3: User cleanup — $user"

    # 3a. Containers
    echo "  Containers..."
    remove_matching "$home/Library/Containers" "com.microsoft.*"

    # 3b. Group Containers
    echo "  Group Containers..."
    remove_matching "$home/Library/Group Containers" "UBF8T346G9.*"

    # 3c. Application Scripts
    echo "  Application Scripts..."
    remove_matching "$home/Library/Application Scripts" "com.microsoft.*"
    remove_matching "$home/Library/Application Scripts" "UBF8T346G9.*"

    # 3d. Application Support
    echo "  Application Support..."
    # Subdirs inside ~/Library/Application Support/Microsoft/
    local ms_as="$home/Library/Application Support/Microsoft"
    if [ -d "$ms_as" ]; then
        for sub in "$ms_as"/*; do
            [ -e "$sub" ] || continue
            is_excluded "$(basename "$sub")" && continue
            remove_item "$sub"
        done
        # Remove parent if empty
        [ -d "$ms_as" ] && [ -z "$(ls -A "$ms_as" 2>/dev/null)" ] && remove_item "$ms_as"
    fi
    remove_item "$home/Library/Application Support/OneDrive"
    remove_matching "$home/Library/Application Support" "com.microsoft.*"

    # 3e. Preferences
    echo "  Preferences..."
    remove_matching "$home/Library/Preferences" "com.microsoft.*"

    # 3f. Caches
    echo "  Caches..."
    remove_matching "$home/Library/Caches" "com.microsoft.*"
    remove_item "$home/Library/Caches/OneDrive"
    remove_item "$home/Library/Caches/Microsoft"
    remove_item "$home/Library/Caches/Microsoft Office"

    # 3g. Saved Application State
    echo "  Saved Application State..."
    remove_matching "$home/Library/Saved Application State" "com.microsoft.*"

    # 3h. Logs
    echo "  Logs..."
    for logdir in "$home/Library/Logs"/Microsoft*; do
        [ -e "$logdir" ] || continue
        is_excluded "$(basename "$logdir")" && continue
        remove_item "$logdir"
    done
    remove_item "$home/Library/Logs/OneDrive"

    # 3i. WebKit
    echo "  WebKit data..."
    remove_matching "$home/Library/WebKit" "com.microsoft.*"

    # 3j. HTTPStorages
    echo "  HTTP Storages..."
    remove_matching "$home/Library/HTTPStorages" "com.microsoft.*"

    # 3k. Cookies
    echo "  Cookies..."
    remove_matching "$home/Library/Cookies" "com.microsoft.*"

    # 3l. User Launch Agents
    echo "  User Launch Agents..."
    for la in "$home/Library/LaunchAgents"/com.microsoft.*; do
        [ -e "$la" ] || continue
        is_excluded "$(basename "$la")" && continue
        if [ -n "$uid" ]; then
            unload_and_remove "$la" "gui/$uid"
        else
            remove_item "$la"
        fi
    done

    # 3m. Login Items (legacy + modern SMAppService / BTM)
    echo "  Login Items..."
    if ! $DRY_RUN; then
        # Build AppleScript exclusions dynamically
        local as_exc=""
        $KEEP_EDGE   && as_exc="$as_exc"$'\n'"if itemName contains \"Edge\" then set shouldRemove to false"
        $KEEP_WINAPP && as_exc="$as_exc"$'\n'"if itemName contains \"Remote Desktop\" then set shouldRemove to false"
        $KEEP_WINAPP && as_exc="$as_exc"$'\n'"if itemName contains \"Windows App\" then set shouldRemove to false"
        $KEEP_MAU    && as_exc="$as_exc"$'\n'"if itemName contains \"AutoUpdate\" then set shouldRemove to false"

        sudo -u "$user" osascript -e "
            tell application \"System Events\"
                repeat with anItem in (every login item)
                    set itemName to name of anItem
                    if itemName contains \"Microsoft\" or itemName contains \"OneDrive\" or itemName contains \"Teams\" or itemName contains \"SharePoint\" then
                        set shouldRemove to true
                        ${as_exc}
                        if shouldRemove then delete anItem
                    end if
                end repeat
            end tell" 2>/dev/null \
            && echo -e "  ${GREEN}[CLEANED]${NC} Legacy login items" \
            || echo -e "  ${DIM}[SKIP]${NC}    No legacy login items (or System Events unavailable)"

        # Force Background Task Management agent to re-evaluate (clears stale
        # SMAppService entries whose app bundles no longer exist).
        killall backgroundtaskmanagementagent 2>/dev/null || true
        echo -e "  ${GREEN}[RESET]${NC}  Background Task Manager cache"
    else
        echo -e "  ${CYAN}[DRY RUN]${NC} Would clean login items and reset BTM agent"
    fi

    # 3n. Dock icons
    echo "  Dock icons..."
    local dock_plist="$home/Library/Preferences/com.apple.dock.plist"
    if [ -f "$dock_plist" ]; then
        local dock_changed=false
        for dock_section in "persistent-apps" "persistent-others"; do
            local i=0 indices_to_remove=()
            while true; do
                local label
                label=$(/usr/libexec/PlistBuddy -c \
                    "Print :${dock_section}:${i}:tile-data:file-label" \
                    "$dock_plist" 2>/dev/null) || break
                if [[ "$label" == *Microsoft* || "$label" == "OneDrive" || "$label" == *Teams* || "$label" == *SharePoint* ]]; then
                    is_excluded "$label" || indices_to_remove+=("$i")
                fi
                i=$((i + 1))
            done
            # Remove in reverse order so indices stay valid
            local j=${#indices_to_remove[@]}
            while [ "$j" -gt 0 ]; do
                j=$((j - 1))
                local idx="${indices_to_remove[$j]}"
                local lbl
                lbl=$(/usr/libexec/PlistBuddy -c \
                    "Print :${dock_section}:${idx}:tile-data:file-label" \
                    "$dock_plist" 2>/dev/null || echo "?")
                if $DRY_RUN; then
                    echo -e "  ${CYAN}[DRY RUN]${NC} Would remove Dock icon: $lbl"
                else
                    /usr/libexec/PlistBuddy -c "Delete :${dock_section}:${idx}" \
                        "$dock_plist" 2>/dev/null
                    echo -e "  ${GREEN}[REMOVED]${NC} Dock icon: $lbl"
                fi
                dock_changed=true
            done
        done
        $dock_changed && ! $DRY_RUN && killall Dock 2>/dev/null || true
    fi

    # 3o. OneDrive data folders
    local found_od=false
    for od_dir in "$home"/OneDrive*; do
        [ -d "$od_dir" ] || continue
        found_od=true
        local fcount
        fcount=$(find "$od_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${YELLOW}OneDrive data: $od_dir ($fcount files)${NC}"
        if $DRY_RUN; then
            echo -e "  ${CYAN}[DRY RUN]${NC} Would prompt for deletion"
        elif prompt_yn "    Delete this folder and all contents?"; then
            remove_item "$od_dir"
        else
            echo -e "    ${YELLOW}[KEPT]${NC}"
            SKIPPED=$((SKIPPED + 1))
        fi
    done
    $found_od || true

    # 3p. Legacy Office data
    remove_item "$home/Documents/Microsoft User Data"
}

for tu in "${TARGET_USERS[@]}"; do
    clean_user "$tu"
done

# ==============================================================================
# Phase 4 — System-level cleanup
# ==============================================================================
section "Phase 4: System cleanup"

# 4a. Launch Daemons
echo "  Launch Daemons..."
for ld in /Library/LaunchDaemons/com.microsoft.*; do
    [ -e "$ld" ] || continue
    is_excluded "$(basename "$ld")" && continue
    unload_and_remove "$ld" "system"
done

# 4b. System Launch Agents
echo "  System Launch Agents..."
for la in /Library/LaunchAgents/com.microsoft.*; do
    [ -e "$la" ] || continue
    is_excluded "$(basename "$la")" && continue
    unload_and_remove "$la" "system"
done

# 4c. Privileged Helper Tools
echo "  Privileged Helper Tools..."
remove_item "/Library/PrivilegedHelperTools/com.microsoft.office.licensingV2.helper"
$KEEP_MAU || remove_item "/Library/PrivilegedHelperTools/com.microsoft.autoupdate.helper"

# 4d. System Application Support
echo "  System Application Support..."
SYS_MS="/Library/Application Support/Microsoft"
if [ -d "$SYS_MS" ]; then
    for sub in "$SYS_MS"/*; do
        [ -e "$sub" ] || continue
        is_excluded "$(basename "$sub")" && continue
        remove_item "$sub"
    done
    [ -d "$SYS_MS" ] && [ -z "$(ls -A "$SYS_MS" 2>/dev/null)" ] && remove_item "$SYS_MS"
fi

# 4e. System Preferences
echo "  System Preferences..."
for pref in /Library/Preferences/com.microsoft.*; do
    [ -e "$pref" ] || continue
    is_excluded "$(basename "$pref")" && continue
    remove_item "$pref"
done

# 4f. Managed Preferences (MDM remnants)
echo "  Managed Preferences..."
for mp in /Library/Managed\ Preferences/com.microsoft.* /Library/Managed\ Preferences/*/com.microsoft.*; do
    [ -e "$mp" ] || continue
    is_excluded "$(basename "$mp")" && continue
    remove_item "$mp"
done

# 4g. Installer receipts
echo "  Installer receipts..."
for receipt in /var/db/receipts/com.microsoft.*; do
    [ -e "$receipt" ] || continue
    is_excluded "$(basename "$receipt")" && continue
    remove_item "$receipt"
done

# 4h. Fonts
if $REMOVE_FONTS; then
    echo "  Microsoft fonts..."
    remove_item "/Library/Fonts/Microsoft"
    # Individual MS fonts that may live directly in /Library/Fonts
    for font in "/Library/Fonts"/MS\ * "/Library/Fonts"/Calibri* "/Library/Fonts"/Cambria* \
                "/Library/Fonts"/Candara* "/Library/Fonts"/Consola* "/Library/Fonts"/Constantia* \
                "/Library/Fonts"/Corbel*; do
        [ -e "$font" ] || continue
        remove_item "$font"
    done
fi

# 4i. Kernel / system extensions
echo "  Extensions..."
remove_item "/Library/Extensions/Microsoft Teams Audio.kext"

# 4j. Internet Plug-Ins
echo "  Internet Plug-Ins..."
for plugin in "/Library/Internet Plug-Ins"/Microsoft* "/Library/Internet Plug-Ins"/SharePoint*; do
    [ -e "$plugin" ] || continue
    is_excluded "$(basename "$plugin")" && continue
    remove_item "$plugin"
done

# ==============================================================================
# Phase 5 — Discovery scan
# ==============================================================================
section "Phase 5: Discovery scan for remaining traces"
echo "  Scanning (this may take a moment)..."

# Scan system and Library directories only — never touch user documents.
SCAN_DIRS=(/Applications /Library /var/db/receipts)
for tu in "${TARGET_USERS[@]}"; do
    SCAN_DIRS+=("/Users/$tu/Library")
done

DISCOVERY_FILE=$(mktemp)
for sd in "${SCAN_DIRS[@]}"; do
    [ -d "$sd" ] || continue
    find "$sd" -maxdepth 5 \
        \( -path '*/.Trash/*' -prune \) \
        -o \( -iname '*microsoft*' -o -iname '*onedrive*' -o -iname 'UBF8T346G9*' \) -print \
        2>/dev/null >> "$DISCOVERY_FILE" || true
done

# De-duplicate, sort, then filter out items belonging to kept apps
REMAINING=$(sort -u "$DISCOVERY_FILE")
rm -f "$DISCOVERY_FILE"
if $KEEP_EDGE; then
    REMAINING=$(echo "$REMAINING" | grep -vi "edge\|/Library/Microsoft$\|/Library/Microsoft/" || true)
fi
if $KEEP_WINAPP; then
    REMAINING=$(echo "$REMAINING" | grep -vi "remote.desktop\|\.rdc\.\|windows.app" || true)
fi

if [ -n "$REMAINING" ]; then
    DISC_COUNT=$(echo "$REMAINING" | wc -l | tr -d ' ')
    echo ""
    echo -e "  ${YELLOW}Found $DISC_COUNT remaining Microsoft-related item(s):${NC}"
    echo ""
    echo "$REMAINING" | head -60 | while IFS= read -r item; do
        echo -e "    ${DIM}$item${NC}"
    done
    [ "$DISC_COUNT" -gt 60 ] && echo -e "    ${DIM}... and $((DISC_COUNT - 60)) more${NC}"
    echo ""

    if $DRY_RUN; then
        echo -e "  ${CYAN}[DRY RUN]${NC} Would prompt to remove discovered items"
    elif prompt_yn "  Remove ALL discovered items?"; then
        while IFS= read -r item; do
            remove_item "$item"
        done <<< "$REMAINING"
    else
        echo -e "  ${YELLOW}[KEPT]${NC} Discovered items left in place"
    fi
else
    echo -e "  ${GREEN}No additional Microsoft traces found.${NC}"
fi

# ==============================================================================
# Phase 6 — Refresh system state
# ==============================================================================
if ! $DRY_RUN; then
    section "Phase 6: Refreshing system state"

    echo "  Refreshing Launch Services database..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -kill -r -domain local -domain system -domain user 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} Launch Services refreshed"

    echo "  Restarting Finder (clears sidebar & extension state)..."
    killall Finder 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} Finder restarted"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "============================================================="
echo " CLEANUP COMPLETE"
$DRY_RUN && echo -e " ${CYAN}*** DRY RUN — nothing was actually deleted ***${NC}"
echo "============================================================="
echo -e " ${GREEN}Removed:${NC} $REMOVED items"
echo -e " ${YELLOW}Skipped:${NC} $SKIPPED items"
echo -e " ${RED}Failed:${NC}  $FAILED items"
echo ""
echo " REMAINING MANUAL STEPS:"
echo "  1. Open Keychain Access -> search 'Microsoft' -> delete entries"
echo "  2. Empty Trash"
echo "  3. Restart your Mac (finalises BTM/startup item cleanup)"
echo "============================================================="
