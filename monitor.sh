#!/bin/bash
echo "Starte Live-Überwachung für PC-Verbindung..."
echo "Warte auf 'Ghost Mode' Aktivierung vom PC..."

LAST_HASH=$(git rev-parse HEAD)

while true; do
    git fetch origin master > /dev/null 2>&1
    REMOTE_HASH=$(git rev-parse origin/master)
    
    if [ "$LAST_HASH" != "$REMOTE_HASH" ]; then
        echo "⚠️  NEUES SIGNAL VOM PC EMPFANGEN!"
        echo "    Neuer Commit: $REMOTE_HASH"
        git pull origin master
        echo "    Update geladen. Prüfe Status..."
        cat Logs/LIVE_STATUS.md
        LAST_HASH=$REMOTE_HASH
    else
        echo -ne "."
    fi
    sleep 5
done
