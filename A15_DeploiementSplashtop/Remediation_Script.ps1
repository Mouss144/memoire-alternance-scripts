#!/bin/zsh

set -u

log() {
  echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $1"
}

console_user=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && $3 != "loginwindow" { print $3 }')
[[ -z "${console_user:-}" ]] && console_user=$(/usr/bin/stat -f '%Su' /dev/console)

log "Starting Atera + bundled Splashtop removal"
log "Console user: ${console_user:-none}"

log "Stopping Atera first to prevent it from relaunching Splashtop"

/bin/launchctl bootout system /Library/LaunchDaemons/com.atera.ateraagent.plist 2>/dev/null || true
/bin/launchctl remove com.atera.ateraagent 2>/dev/null || true

/usr/bin/pkill -f "Atera.Agent.Mac.dll" 2>/dev/null || true
/usr/bin/pkill -f "com.atera.ateraagent" 2>/dev/null || true
/usr/bin/pkill -f "AteraAgent" 2>/dev/null || true

/bin/sleep 2

log "Running Splashtop official uninstall logic if available"

splashtop_app="/Applications/Splashtop Streamer.app"
official_uninstall=""

candidate_paths=(
  "$splashtop_app/Contents/Resources/uninstall.sh"
  "$splashtop_app/Contents/Resources/scripts/uninstall.sh"
  "$splashtop_app/Contents/Resources/uninstall_streamer.sh"
  "$splashtop_app/Contents/MacOS/uninstall.sh"
)

for candidate in "${candidate_paths[@]}"; do
  if [[ -f "$candidate" ]]; then
    official_uninstall="$candidate"
    break
  fi
done

if [[ -n "$official_uninstall" ]]; then
  log "Found official Splashtop uninstaller: $official_uninstall"
  /bin/chmod +x "$official_uninstall" 2>/dev/null || true
  "$official_uninstall" "$console_user" 2>&1 || true
else
  log "No embedded Splashtop uninstaller found. Using fallback cleanup."
fi

log "Unloading Splashtop launch services"

splashtop_labels=(
  "com.splashtop.streamer"
  "com.splashtop.streamer-daemon"
  "com.splashtop.streamer-for-user"
  "com.splashtop.streamer-for-root"
  "com.splashtop.streamer.SRServiceAgent"
  "com.splashtop.streamer.SRServiceDaemon"
  "com.splashtop.streamer-srioframebuffer"
  "com.splashtop-streamer.usbhelper"
  "com.splashtop.antivirus.daemons"
)

if [[ -n "${console_user:-}" && "$console_user" != "root" && "$console_user" != "loginwindow" ]]; then
  console_uid=$(/usr/bin/id -u "$console_user" 2>/dev/null || true)
else
  console_uid=""
fi

for label in "${splashtop_labels[@]}"; do
  /bin/launchctl remove "$label" 2>/dev/null || true
  /bin/launchctl bootout "system/$label" 2>/dev/null || true

  if [[ -n "${console_uid:-}" ]]; then
    /bin/launchctl bootout "gui/$console_uid/$label" 2>/dev/null || true
    /bin/launchctl asuser "$console_uid" /bin/launchctl remove "$label" 2>/dev/null || true
  fi
done

log "Removing launch plist files"

while IFS= read -r plist; do
  log "Removing plist: $plist"
  /bin/launchctl bootout system "$plist" 2>/dev/null || true
  if [[ -n "${console_uid:-}" ]]; then
    /bin/launchctl bootout "gui/$console_uid" "$plist" 2>/dev/null || true
  fi
  /bin/rm -f "$plist" 2>/dev/null || true
done < <(/usr/bin/find /Library/LaunchDaemons /Library/LaunchAgents -iname "*splashtop*.plist" -o -iname "*atera*.plist" 2>/dev/null)

if [[ -n "${console_user:-}" && -d "/Users/$console_user/Library/LaunchAgents" ]]; then
  while IFS= read -r plist; do
    log "Removing user plist: $plist"
    if [[ -n "${console_uid:-}" ]]; then
      /bin/launchctl bootout "gui/$console_uid" "$plist" 2>/dev/null || true
    fi
    /bin/rm -f "$plist" 2>/dev/null || true
  done < <(/usr/bin/find "/Users/$console_user/Library/LaunchAgents" -iname "*splashtop*.plist" -o -iname "*atera*.plist" 2>/dev/null)
fi

log "Stopping remaining processes"

processes=(
  "Atera.Agent.Mac.dll"
  "com.atera.ateraagent"
  "AteraAgent"
  "Splashtop Streamer"
  "SRStreamerDaemon"
  "SplashtopPMService"
  "SRManager"
  "SplashtopStreamer"
  "SSUAgent"
  "SRFeature"
  "SplashtopRemote"
  "SRProxy"
  "spupnp"
  "inputserv"
)

for process in "${processes[@]}"; do
  /usr/bin/pkill -f "$process" 2>/dev/null || true
done

/bin/sleep 3

for process in "${processes[@]}"; do
  /usr/bin/pkill -9 -f "$process" 2>/dev/null || true
done

log "Removing Atera files"

atera_paths=(
  "/Library/Application Support/com.atera.ateraagent"
  "/Library/Application Support/Atera"
  "/Applications/AteraAgent.app"
  "/Applications/Atera.app"
  "/Library/Logs/Atera"
  "/Library/LaunchDaemons/com.atera.ateraagent.plist"
)

for path in "${atera_paths[@]}"; do
  if [[ -e "$path" ]]; then
    log "Removing: $path"
    /bin/rm -rf "$path" 2>/dev/null || true
  fi
done

log "Removing Splashtop residual files"

splashtop_paths=(
  "/Applications/Splashtop Streamer.app"
  "/Applications/SplashtopRemote.app"
  "/Applications/SplashtopRemoteStreamer.app"
  "/Applications/Splashtop Streamer for Business.app"
  "/Library/Application Support/Splashtop"
  "/Library/Application Support/Splashtop Streamer"
  "/Library/Logs/Splashtop"
  "/Users/Shared/SplashtopStreamer"
  "/Library/Frameworks/SRFrameBufferConnection.framework"
  "/Library/Extensions/SRXDisplayCard.kext"
  "/Library/Extensions/SRXFrameBufferConnector.kext"
  "/Library/Extensions/SplashtopSoundDriver.kext"
  "/Library/Audio/Plug-Ins/HAL/SplashtopRemoteSound.driver"
  "/Library/Audio/Plug-Ins/HAL/SplashtopRemoteMic.driver"
)

for path in "${splashtop_paths[@]}"; do
  if [[ -e "$path" ]]; then
    log "Removing: $path"
    /bin/rm -rf "$path" 2>/dev/null || true
  fi
done

log "Removing user-level Splashtop preferences and caches"

for user_home in /Users/*; do
  [[ -d "$user_home" ]] || continue

  /bin/rm -rf "$user_home/Library/Preferences/com.splashtop."* 2>/dev/null || true
  /bin/rm -rf "$user_home/Library/Caches/com.splashtop.Splashtop-Streamer" 2>/dev/null || true
  /bin/rm -rf "$user_home/Library/Saved Application State/com.splashtop.Splashtop-Streamer.savedState" 2>/dev/null || true
  /bin/rm -rf "$user_home/Library/Application Support/Splashtop Streamer" 2>/dev/null || true
done

log "Forgetting package receipts"

receipts=$(/usr/sbin/pkgutil --pkgs | /usr/bin/egrep -i 'atera|splashtop' || true)

if [[ -n "$receipts" ]]; then
  echo "$receipts" | while read -r receipt; do
    log "Forgetting receipt: $receipt"
    /usr/sbin/pkgutil --forget "$receipt" 2>/dev/null || true
  done
else
  log "No Atera or Splashtop receipts found"
fi

log "Restarting CoreAudio if Splashtop audio drivers were removed"

/bin/launchctl kickstart -kp system/com.apple.audio.coreaudiod 2>/dev/null || true

log "Final verification"

remaining=$(/bin/ps aux | /usr/bin/egrep -i 'Atera.Agent.Mac.dll|com.atera.ateraagent|SRStreamerDaemon|SplashtopPMService|Splashtop Streamer|SRManager|SplashtopStreamer' | /usr/bin/grep -v grep || true)

if [[ -n "$remaining" ]]; then
  log "Some processes are still running. Logout or reboot may be required, but reboot is not forced."
  echo "$remaining"
else
  log "No Atera or Splashtop processes detected"
fi

log "Removal completed"
exit 0