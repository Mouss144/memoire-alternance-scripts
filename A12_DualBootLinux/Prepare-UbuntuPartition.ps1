#
# Prepare-UbuntuPartition.ps1
# Prepare une partition de 80 GB pour Ubuntu en dual boot.
# Strategie 1 : second disque physique -> init GPT + partition RAW
# Strategie 2 : disque unique -> shrink C: de 80 GB
#
# TEST LOCAL  : powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\Prepare-UbuntuPartition.ps1"
# INTUNE      : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NonInteractive -File Prepare-UbuntuPartition.ps1
#

$TargetGB   = 80
$LogDir     = "C:\ProgramData\Intune\Ubuntu"
$LogFile    = "$LogDir\PrepDisk.log"
$MarkerFile = "$LogDir\DiskReady.flag"
$JsonFile   = "$MarkerFile.json"

function Write-Log {
    param(
        [string]$Msg,
        [string]$Level = "INFO"
    )
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts [$Level] $Msg"
    if ($Level -eq "ERROR") {
        Write-Host $line -ForegroundColor Red
    } elseif ($Level -eq "WARN") {
        Write-Host $line -ForegroundColor Yellow
    } else {
        Write-Host $line -ForegroundColor Cyan
    }
    $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

Write-Log "--- Demarrage Prepare-UbuntuPartition.ps1 ---"
Write-Log "Cible : $TargetGB GB | Machine : $env:COMPUTERNAME"

if (Test-Path $MarkerFile) {
    Write-Log "Partition Ubuntu deja preparee. Sortie propre."
    exit 0
}

# Strategie 1 : second disque
Write-Log "Recherche d'un second disque physique..."

$disk2 = Get-Disk | Where-Object {
    $_.Number -ne 0 -and
    $_.BusType -notin @("USB","SD","iSCSI") -and
    $_.OperationalStatus -eq "Online"
} | Sort-Object Size -Descending | Select-Object -First 1

if ($disk2) {
    $diskSizeGB = [math]::Round($disk2.Size / 1GB, 1)
    Write-Log "Second disque detecte : Disk $($disk2.Number) - $diskSizeGB GB"

    if (($disk2.Size / 1GB) -lt $TargetGB) {
        Write-Log "Disque trop petit : $diskSizeGB GB disponible, $TargetGB GB requis." "ERROR"
        exit 1
    }

    try {
        Write-Log "Nettoyage du Disk $($disk2.Number)..."
        Clear-Disk -Number $disk2.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop

        Write-Log "Initialisation GPT..."
        Initialize-Disk -Number $disk2.Number -PartitionStyle GPT -Confirm:$false -ErrorAction Stop

        Write-Log "Creation partition RAW..."
        $part = New-Partition -DiskNumber $disk2.Number -UseMaximumSize -ErrorAction Stop
        Write-Log "Partition RAW creee : numero $($part.PartitionNumber)"

        $info = @{
            Strategy   = "SecondDisk"
            DiskNumber = $disk2.Number
            PartNumber = $part.PartitionNumber
            SizeGB     = $diskSizeGB
            Date       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $info | ConvertTo-Json | Set-Content $JsonFile -Encoding UTF8
        Write-Log "Strategie SecondDisk appliquee avec succes."
    }
    catch {
        Write-Log "Erreur lors de l'init disque : $($_.Exception.Message)" "ERROR"
        exit 1
    }
}
else {
    # Strategie 2 : Shrink C:
    Write-Log "Pas de second disque - strategie ShrinkC."

    try {
        $bl = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
        if ($bl -and $bl.ProtectionStatus -eq "On") {
            Write-Log "BitLocker actif - suspension pour 1 redemarrage..." "WARN"
            Suspend-BitLocker -MountPoint C: -RebootCount 1 -ErrorAction Stop
            Write-Log "BitLocker suspendu."
        } else {
            Write-Log "BitLocker non actif sur C: - pas de suspension necessaire."
        }
    }
    catch {
        Write-Log "Avertissement BitLocker : $($_.Exception.Message)" "WARN"
    }

    try {
        $cPart   = Get-Partition -DriveLetter C -ErrorAction Stop
        $sizes   = Get-PartitionSupportedSize -DriveLetter C -ErrorAction Stop
        $current = $cPart.Size
        $newSize = $current - ($TargetGB * 1GB)

        Write-Log "Taille actuelle C: : $([math]::Round($current/1GB,1)) GB"
        Write-Log "Taille min supportee : $([math]::Round($sizes.SizeMin/1GB,1)) GB"
        Write-Log "Taille apres shrink : $([math]::Round($newSize/1GB,1)) GB"

        if ($newSize -lt $sizes.SizeMin) {
            Write-Log "Espace insuffisant pour reserver $TargetGB GB sur C:." "ERROR"
            exit 1
        }
    }
    catch {
        Write-Log "Impossible de lire la partition C: : $($_.Exception.Message)" "ERROR"
        exit 1
    }

    try {
        Write-Log "Execution du Resize-Partition..."
        Resize-Partition -DriveLetter C -Size $newSize -Confirm:$false -ErrorAction Stop
        Write-Log "C: reduit avec succes. Espace libre = $TargetGB GB en RAW."

        $info = @{
            Strategy   = "ShrinkC"
            DiskNumber = $cPart.DiskNumber
            FreeGB     = $TargetGB
            NewCSizeGB = [math]::Round($newSize/1GB,1)
            Date       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $info | ConvertTo-Json | Set-Content $JsonFile -Encoding UTF8
        Write-Log "Strategie ShrinkC appliquee avec succes."
    }
    catch {
        Write-Log "Erreur Resize-Partition : $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

"READY $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content $MarkerFile -Encoding UTF8

Write-Log "--- Partition Ubuntu prete pour l'installeur ---"
Write-Log "Marker : $MarkerFile"
Write-Log "Details : $JsonFile"

exit 0