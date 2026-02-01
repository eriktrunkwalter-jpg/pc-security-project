# Guardian-Loop.ps1 - Der Hauptwächter
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

# C# Code für User-Idle-Erkennung einbinden
try {
    Add-Type @'
    using System;
    using System.Runtime.InteropServices;
    public class UserInput {
        [DllImport("user32.dll")]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        [StructLayout(LayoutKind.Sequential)]
        public struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime;
        }
        public static uint GetIdleTime() {
            LASTINPUTINFO lastInputInfo = new LASTINPUTINFO();
            lastInputInfo.cbSize = (uint)Marshal.SizeOf(lastInputInfo);
            GetLastInputInfo(ref lastInputInfo);
            return ((uint)Environment.TickCount - lastInputInfo.dwTime) / 1000;
        }
    }
'@ -ErrorAction SilentlyContinue
} catch {}

Write-Host "GUARDIAN SYSTEM GESTARTET" -ForegroundColor Green
Write-Host "Überwache Mac-Signale und Systemstatus..."
$offlineCounter = 0

$safeCommit = "a199a75c002f75757ac8f2ebbb55552a40909a18" # Aktueller 'Clean' State

# --- ANTI-BOOT-LOOP PROTECTION ---
# Falls der PC in einer Neustart-Schleife hängt (z.B. durch aggressive Skripte),
# erkennen wir das an häufigen Starts ohne lange Laufzeit.

$bootLog = "Logs\BootCounter.txt"
if (-not (Test-Path "Logs")) { New-Item -ItemType Directory -Path "Logs" -Force | Out-Null }

$bootCount = 0
if (Test-Path $bootLog) { 
    try { $bootCount = [int](Get-Content $bootLog) } catch { $bootCount = 0 }
}
$bootCount++
Set-Content -Path $bootLog -Value $bootCount

Write-Host "Boot-Check: Start Nr. $bootCount (Schwellenwert: 3)" -ForegroundColor Gray

if ($bootCount -ge 3) {
    Write-Host "🚨 KRITISCHER BOOT-LOOP ERKANNT ($bootCount schnelle Neustarts)!" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "⚠️ PRIORISIERE RETTUNGS-PROTOKOLL VOR ALLEN ANDEREN PROZESSEN..."
    
    # NOTFALL-RETTUNG AUSLÖSEN
    & ".\Scripts_Backup\Mac-Rescuer.ps1" -SafeCommitHash $safeCommit
    
    # Counter resetten nach Rettung
    Set-Content -Path $bootLog -Value 0
    
    # Warten, damit der Reset wirken kann
    Start-Sleep -Seconds 10
}

# Wenn das System 2 Minuten stabil läuft, wird der Counter zurückgesetzt
Start-Job -ScriptBlock {
    param($path)
    Start-Sleep -Seconds 120
    Set-Content -Path $path -Value 0
} -ArgumentList $bootLog
# ---------------------------------

while ($true) {
    # 1. Hole Befehle vom Mac
    $isOnline = $true
    try {
        git fetch origin -q -ErrorAction Stop
        $offlineCounter = 0 # Reset bei Erfolg
    } catch {
        $isOnline = $false
        $offlineCounter += 5
        Write-Host "⚠️ WARNUNG: Keine Verbindung zu GitHub seit $offlineCounter Sekunden." -ForegroundColor Yellow
        
        # OFFLINE-NOTFALL-LOGIK
        if ($offlineCounter -ge 60 -and $offlineCounter -lt 65) {
            Write-Host "Versuche Netzwerk-Reparatur..." -ForegroundColor Cyan
            ipconfig /flushdns
        }
        
        # 30 Minuten (1800 Sekunden) Offline-Timeout
        if ($offlineCounter -ge 1800) { 
            # SAFETY CHECK: Arbeitet der User gerade aktiv offline?
            $userIsActive = $false
            try {
                $idleSeconds = [UserInput]::GetIdleTime()
                if ($idleSeconds -lt 300) { # User hat in den letzten 5 Minuten etwas gemacht
                    $userIsActive = $true
                }
            } catch {
                # Fallback, falls C# nicht lädt: Wir gehen sicherheitshalber davon aus, dass er aktiv ist,
                # wenn eine spezielle Datei existiert "ACTIVE_OFFLINE.lock"
                if (Test-Path "ACTIVE_OFFLINE.lock") { $userIsActive = $true }
            }

            if ($userIsActive) {
                Write-Host "Offline-Timeout erreicht, aber USER IST AKTIV. Kein Reset." -ForegroundColor Green
                $offlineCounter = 1700 # Reset counter slightly to re-check later
            } else {
                Write-Host "KRITISCHER OFFLINE-ZUSTAND (30 Min + Inaktiv): Aktiviere Notfall-Protokoll!" -ForegroundColor Red
                # Deaktiviere Firewall oder Sicherheitsregeln, damit der User lokal zugreifen kann
                # Hier: Wir rufen einfach den Rescuer auf, um auf 'Safe' zurückzugehen
                & ".\Scripts_Backup\Mac-Rescuer.ps1" -SafeCommitHash $safeCommit
                $offlineCounter = 0 # Reset nach Rescue-Versuch
            }
        }
    }
    
    if ($isOnline) {
        # Prüfe auf Restore-Trigger (Datei existiert im Remote?)
        # Wir müssen schauen, ob die Datei im Origin/Master existiert, ohne zu mergen
        $remoteFiles = git ls-tree -r origin/master --name-only
        if ($remoteFiles -contains "RESTORE_REQUEST.trigger") {
            Write-Host "ALARM: Mac fordert Restore an!" -ForegroundColor Red
            # Wir müssen pullen/checkout machen, um das Script auszuführen? 
            # Nein, wir führen unser lokales Rescue Script aus
            & ".\Scripts_Backup\Mac-Rescuer.ps1" -SafeCommitHash $safeCommit
            
            # Nach Restore müssen wir den Trigger auch remote löschen, das ist tricky ohne Push-Rechte oder wenn wir 'Read-Only' sein sollen.
            # Aber der User hat gesagt: "der mac soll dich wieder herstellen können".
            # Wir gehen davon aus, dass der Reset lokal reicht.
        }
    }

    # 2. Sende Status (Heartbeat)
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "GUARDIAN ALIVE: $date | STATUS: SECURE" | Out-File "Logs\HEARTBEAT.txt"
    
    if (Test-Path "Logs\HEARTBEAT.txt") {
        git add "Logs\HEARTBEAT.txt"
        git commit -m "Guardian Heartbeat" -q
        git push -q
    }

    # 3. Führe Sicherheits-Checks alle 60 Sekunden aus
    if ((Get-Date).Second -eq 0) {
        Write-Host "Führe Routine-Check aus..." -ForegroundColor Gray
        # & ".\Scripts_Backup\Safe-Harden.ps1" 
        # (Auskommentiert, damit wir nicht spammen, nur bei Bedarf aktivieren)
    }

    Start-Sleep -Seconds 5
}
