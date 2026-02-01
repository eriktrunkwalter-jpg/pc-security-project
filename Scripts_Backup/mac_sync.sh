#!/bin/bash
# Mac Live-Sync Simulation
# Dieses Skript simuliert die Gegenseite (den PC) sicher auf dem Mac.
# Es prüft alle 5 Sekunden auf Updates.

echo "Starte Mac Live-Sync (Safe Mode)..."
echo "Drücken Sie Ctrl+C zum Beenden."

while true; do
    echo "Prüfe auf Updates..."
    git pull
    
    if [ -f "../PC_Connection_Test.txt" ]; then
        echo "PC-Verbindungstest gefunden!"
        cat "../PC_Connection_Test.txt"
    fi
    
    sleep 5
done
