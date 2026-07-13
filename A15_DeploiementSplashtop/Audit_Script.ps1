#!/bin/zsh

if [[ -d "/Library/Application Support/com.atera.ateraagent" ]]; then
  echo "Atera still installed"
  exit 1
fi

if [[ -f "/Library/LaunchDaemons/com.atera.ateraagent.plist" ]]; then
  echo "Atera LaunchDaemon still present"
  exit 1
fi

if /bin/ps aux | /usr/bin/egrep -i 'Atera.Agent.Mac.dll|com.atera.ateraagent' | /usr/bin/grep -v grep >/dev/null; then
  echo "Atera still running"
  exit 1
fi

echo "Atera not detected"
exit 0