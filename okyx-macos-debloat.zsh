#!/bin/zsh
#
# Okyx macOS Debloat Utility
# Conservative macOS cleanup/debloat helper for Apple Silicon Macs.
#
# Design goals:
#   - Do NOT modify /System or the sealed system volume
#   - Do NOT disable SIP
#   - Do NOT disable Gatekeeper
#   - Do NOT remove critical Apple frameworks/services
#   - Create a backup before changing user defaults
#   - Ask before destructive operations
#
# Tested conceptually for modern macOS on Apple Silicon.
#

setopt NO_NOMATCH

APP_NAME="Okyx macOS Debloat Utility"
BACKUP_DIR="$HOME/Desktop/Okyx-macOS-Debloat-Backup-$(date +%Y%m%d-%H%M%S)"

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

pause() {
    echo
    read "?Press Enter to continue..."
}

confirm() {
    local answer
    read "answer?$1 [y/N]: "
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

need_admin() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "${YELLOW}This operation requires administrator privileges.${RESET}"
        sudo -v || return 1
    fi
}

backup_defaults() {
    mkdir -p "$BACKUP_DIR"
    defaults read > "$BACKUP_DIR/global-defaults.txt" 2>/dev/null || true
    defaults read com.apple.Siri > "$BACKUP_DIR/com.apple.Siri.txt" 2>/dev/null || true
    defaults read com.apple.Spotlight > "$BACKUP_DIR/com.apple.Spotlight.txt" 2>/dev/null || true
    defaults read com.apple.dock > "$BACKUP_DIR/com.apple.dock.txt" 2>/dev/null || true
    defaults read com.apple.finder > "$BACKUP_DIR/com.apple.finder.txt" 2>/dev/null || true
    echo "${GREEN}Backup information saved to:${RESET}"
    echo "$BACKUP_DIR"
}

header() {
    clear
    echo "${CYAN}${BOLD}==============================================${RESET}"
    echo "${CYAN}${BOLD}       $APP_NAME${RESET}"
    echo "${CYAN}${BOLD}==============================================${RESET}"
    echo "Mac: $(sw_vers -productName) $(sw_vers -productVersion)"
    echo "Chip: $(sysctl -n hw.optional.arm64 2>/dev/null | grep -q 1 && echo 'Apple Silicon' || echo 'Intel')"
    echo
}

show_safe_info() {
    header
    echo "${BOLD}What this tool intentionally does NOT do:${RESET}"
    echo
    echo "  • Does not modify /System"
    echo "  • Does not disable SIP"
    echo "  • Does not disable Gatekeeper"
    echo "  • Does not remove system frameworks"
    echo "  • Does not randomly unload launch daemons"
    echo "  • Does not install questionable third-party cleaners"
    echo
    echo "${BOLD}Generally safe cleanup targets:${RESET}"
    echo
    echo "  • Optional Apple applications"
    echo "  • User-level caches"
    echo "  • Homebrew package/cache cleanup"
    echo "  • User preferences such as Siri UI behavior"
    echo "  • Spotlight indexing configuration"
    echo "  • Login/background items for applications you explicitly identify"
    echo
    echo "${YELLOW}Note:${RESET} macOS protects many system components with SIP and the"
    echo "sealed system volume. Trying to fight that protection is not debloating."
    pause
}

remove_optional_apps() {
    header
    echo "${BOLD}Optional Apple Applications${RESET}"
    echo
    echo "The following applications are commonly removable if you do not use them:"
    echo
    echo "  /Applications/GarageBand.app"
    echo "  /Applications/iMovie.app"
    echo "  /Applications/Chess.app"
    echo "  /Applications/Keynote.app"
    echo "  /Applications/Numbers.app"
    echo "  /Applications/Pages.app"
    echo
    echo "This does NOT touch /System/Applications."
    echo

    local apps=(
        "/Applications/GarageBand.app"
        "/Applications/iMovie.app"
        "/Applications/Chess.app"
        "/Applications/Keynote.app"
        "/Applications/Numbers.app"
        "/Applications/Pages.app"
    )

    local found=()
    for app in "${apps[@]}"; do
        [[ -d "$app" ]] && found+=("$app")
    done

    if (( ${#found[@]} == 0 )); then
        echo "${GREEN}None of the selected optional Apple apps were found.${RESET}"
        pause
        return
    fi

    printf '%s\n' "${found[@]}"
    echo
    if ! confirm "Remove these applications?"; then
        echo "Cancelled."
        pause
        return
    fi

    need_admin || { pause; return; }

    for app in "${found[@]}"; do
        echo "Removing: $app"
        sudo rm -rf -- "$app"
    done

    echo "${GREEN}Selected applications removed.${RESET}"
    pause
}

clean_user_caches() {
    header
    echo "${BOLD}User Cache Cleanup${RESET}"
    echo
    echo "This clears contents of your user cache directory."
    echo "Applications may recreate these files automatically."
    echo
    echo "Target: $HOME/Library/Caches"
    echo

    if ! confirm "Continue?"; then
        echo "Cancelled."
        pause
        return
    fi

    mkdir -p "$BACKUP_DIR"
    echo "Saving a directory listing..."
    find "$HOME/Library/Caches" -maxdepth 2 -print > "$BACKUP_DIR/cache-list.txt" 2>/dev/null || true

    echo "Cleaning user caches..."
    find "$HOME/Library/Caches" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

    echo "${GREEN}User cache cleanup completed.${RESET}"
    pause
}

brew_cleanup() {
    header
    if ! command -v brew >/dev/null 2>&1; then
        echo "${YELLOW}Homebrew is not installed.${RESET}"
        pause
        return
    fi

    echo "${BOLD}Homebrew Cleanup${RESET}"
    echo
    brew cleanup -n
    echo
    if confirm "Run Homebrew cleanup?"; then
        brew cleanup
        echo "${GREEN}Homebrew cleanup completed.${RESET}"
    else
        echo "Cancelled."
    fi
    pause
}

disable_siri_ui() {
    header
    echo "${BOLD}Siri / Siri Suggestions${RESET}"
    echo
    echo "This changes user-level Siri UI/preferences only."
    echo "It does NOT remove Siri system components."
    echo
    if ! confirm "Disable Siri-related user interface features?"; then
        echo "Cancelled."
        pause
        return
    fi

    mkdir -p "$BACKUP_DIR"
    defaults read com.apple.Siri > "$BACKUP_DIR/Siri-before.txt" 2>/dev/null || true

    defaults write com.apple.Siri StatusMenuVisible -bool false
    defaults write com.apple.Siri SuggestionsEnabled -bool false 2>/dev/null || true
    defaults write com.apple.Siri UserHasDeclinedEnable -bool true 2>/dev/null || true

    killall SystemUIServer 2>/dev/null || true

    echo "${GREEN}Siri UI preferences changed.${RESET}"
    echo "macOS version differences may cause some settings to be ignored."
    pause
}

spotlight_menu() {
    header
    echo "${BOLD}Spotlight Indexing${RESET}"
    echo
    echo "Disabling Spotlight globally is NOT recommended."
    echo "Instead, this menu lets you exclude specific folders."
    echo
    echo "Current Spotlight status:"
    mdutil -s / 2>/dev/null || true
    echo
    echo "Useful example:"
    echo "  mdutil -i off ~/Downloads"
    echo
    echo "The script will not automatically disable Spotlight."
    pause
}

show_background_items() {
    header
    echo "${BOLD}Login & Background Items${RESET}"
    echo
    echo "macOS controls these through modern background-task mechanisms."
    echo "Rather than blindly unloading services, review Apple's registered items."
    echo
    if command -v sfltool >/dev/null 2>&1; then
        sfltool dumpbtm 2>/dev/null | sed -n '1,220p'
    else
        echo "sfltool is unavailable on this macOS version."
    fi
    echo
    echo "You can disable unwanted third-party items in:"
    echo "System Settings > General > Login Items & Extensions"
    pause
}

developer_cleanup() {
    header
    echo "${BOLD}Developer / Build Cache Cleanup${RESET}"
    echo
    echo "This checks common developer caches. Nothing is removed automatically."
    echo
    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        echo "Xcode DerivedData:"
        du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null
    else
        echo "Xcode DerivedData: not found"
    fi

    if [[ -d "$HOME/Library/Developer/Xcode/Archives" ]]; then
        echo "Xcode Archives:"
        du -sh "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null
    else
        echo "Xcode Archives: not found"
    fi

    if [[ -d "$HOME/Library/Developer/CoreSimulator" ]]; then
        echo "CoreSimulator:"
        du -sh "$HOME/Library/Developer/CoreSimulator" 2>/dev/null
    else
        echo "CoreSimulator: not found"
    fi

    echo
    if confirm "Delete Xcode DerivedData only?"; then
        rm -rf "$HOME/Library/Developer/Xcode/DerivedData"
        echo "${GREEN}DerivedData removed.${RESET}"
    fi
    pause
}

system_info() {
    header
    echo "${BOLD}System Information${RESET}"
    echo
    echo "macOS:"
    sw_vers
    echo
    echo "Hardware:"
    system_profiler SPHardwareDataType 2>/dev/null | sed -n '1,25p'
    echo
    echo "Disk:"
    df -h /
    echo
    echo "Memory pressure:"
    memory_pressure 2>/dev/null | sed -n '1,20p'
    pause
}

main_menu() {
    while true; do
        header
        echo "${BOLD}Choose an operation:${RESET}"
        echo
        echo "  1) Remove optional Apple apps"
        echo "  2) Clean user caches"
        echo "  3) Clean Homebrew"
        echo "  4) Disable Siri UI / suggestions"
        echo "  5) Spotlight information"
        echo "  6) Inspect Login / Background Items"
        echo "  7) Developer / Xcode cache cleanup"
        echo "  8) System information"
        echo "  9) Show safety information"
        echo " 10) Create backup of preferences"
        echo "  0) Exit"
        echo
        read "choice?Select: "

        case "$choice" in
            1) remove_optional_apps ;;
            2) clean_user_caches ;;
            3) brew_cleanup ;;
            4) disable_siri_ui ;;
            5) spotlight_menu ;;
            6) show_background_items ;;
            7) developer_cleanup ;;
            8) system_info ;;
            9) show_safe_info ;;
            10)
                header
                backup_defaults
                pause
                ;;
            0)
                echo
                echo "Done. Your Mac remains mostly intact, which is generally considered"
                echo "a successful outcome in the ancient art of system administration."
                exit 0
                ;;
            *) echo "Invalid selection."; sleep 1 ;;
        esac
    done
}

main_menu
