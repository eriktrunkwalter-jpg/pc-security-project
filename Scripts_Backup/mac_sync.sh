#!/bin/bash
echo "Starte Live-Sync vom Windows PC..."
echo "Drücke STRG+C zum Beenden."

while true; do
  echo "$(date): Prüfe auf Änderungen..."
  git pull
  sleep 10
done
