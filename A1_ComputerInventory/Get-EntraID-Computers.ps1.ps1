#################################### LOGIN GRAPH ####################################
$headers = @{"Content-Type" = "application/x-www-form-urlencoded" }
$body = @{
    client_id     = ""
    scope         = ""
    client_secret = ""
    grant_type    = ""
}
$auth = (Invoke-WebRequest -Uri "https://login.microsoftonline.com/af1bbf3d-7aa3-4e3f-8173-c8889d944e6a/oauth2/v2.0/token" -Method POST -Headers $headers -Body $body).Content | ConvertFrom-Json
$graphVersion = (Get-InstalledModule -Name "Microsoft.Graph").Version
if (!($graphVersion)) { throw "GRAPH MODULE NOT INSTALLED" }
if ($graphVersion[0] -ne "1") {
    Write-Host "USING NEW LOGIN METHOD TO CONNECT MG GRAPH" -b Cyan
    Connect-MgGraph -AccessToken ($auth.access_token | ConvertTo-SecureString -AsPlainText -Force) 
}
else {
    Write-Host "USING OLD LOGIN METHOD TO CONNECT MG GRAPH" -b Yellow
    Connect-MgGraph -AccessToken $auth.access_token
}
################################################################################

# TABLE DES GROUPES PAYS : "Nom affiché" = "Object ID du groupe"
# Ajoute des pays et de leurs Object IDs
$COUNTRY_GROUPS = [ordered]@{
    "Computers FRA" = "9389efb8-6490-4eeb-af65-2b2e20fc5ce9"
    #"Computers GBR" = "bd15d1fa-98e1-415f-a724-411339031c87"
    #"Computers USA" = "e1bee88b-8d59-47c6-a9d0-776673c57e30"
    #"Computers DEU" = "6477abc2-3dfe-4ad9-b5b2-3ebc783b71c8"
    #"Computers BEL" = "b1504e2a-53d5-4aca-a6e3-fc84713492b3"
    #"Computers CHE" = "a70ef68e-4983-470c-bb42-56f5c876ccee"
    #"Computers NLD" = "66a7ce2e-3aa6-460b-82a2-cfe69b8ff289"
    #"Computers LUX" = "7ddd6ee7-ba45-4990-8155-b18d92a6f97e"
    #"Computers IRL" = "2a425345-edee-4cd5-a028-2a14b35b3f98"
    #"Computers MAR" = "077606a4-5b5c-49ce-917e-b2a71b81d7f1"
    #"Computers AUS" = "cbbee715-e10c-4ba7-9bb3-bef4c30fd2f5"
    #"Computers CAN" = "2a9bc900-be23-48ee-a5c7-87cbfefc286d"
    #"Computers SGP" = "f1176682-fa61-49f1-a902-d001d8ed432b"
    #"Computers HKG" = "246ecb3a-89ce-42b2-b45e-2a7941940c2e"
    #"Computers JPN" = "6f4ec374-d587-4da6-acff-e11b4d085a2c"
    #"Computers IND" = "825b24e5-0ee9-4e50-8a4f-e76ee641f29c"
    #"Computers CHN" = "1163c5a8-e783-4617-add9-71064a858cf4"
    #"Computers SAU" = "f9e2f6e0-5429-4394-8840-2dd3d48e0fbd"
    #"Computers ARE" = "f7adfffb-d81b-4cb5-9220-f5dff8512fa3"
    #"Computers Global" = "87697c65-679e-4766-bd2f-d1d2283f645c"
    #"Computers Global" = "87697c65-679e-4766-bd2f-d1d2283f645c"
}

# Séparateur CSV
$CSV_SEPARATOR = ";"

# Dossier de sortie pour les fichiers CSV
$OUTPUT_FOLDER = ".\EntraID_Computers_$(Get-Date -Format 'yyyyMMdd_HHmmss')"


#region --- FONCTIONS HELPERS ---
 
function Get-DevicesFromGroup {
    param(
        [string]$GroupId,
        [string]$CountryLabel
    )
 
    $members = Get-MgGroupMember -GroupId $GroupId -All
 
 
    $results = @()
 
    foreach ($dm in $members) {
        try {
            $device = Get-MgDevice -DeviceId $dm.Id -Property `
                "displayName,deviceId,operatingSystem,operatingSystemVersion,approximateLastSignInDateTime,model,manufacturer,managementType,enrollmentType,physicalIds" `
                -ErrorAction SilentlyContinue
 
            if (-not $device) { continue }
 
            # --- Serial Number ---
            $serialNumber = "N/A"
            if ($device.PhysicalIds) {
                $serialEntry = $device.PhysicalIds | Where-Object { $_ -match '^\[SerialNumber\]:' } | Select-Object -First 1
                if ($serialEntry) {
                    $serialNumber = $serialEntry -replace '^\[SerialNumber\]:', ''
                }
                else {
                    $orderEntry = $device.PhysicalIds | Where-Object { $_ -match '^\[OrderId\]:' } | Select-Object -First 1
                    if ($orderEntry) { $serialNumber = $orderEntry -replace '^\[OrderId\]:', '' }
                }
            }
 
            # --- Device Model ---
            $deviceModel = if ($device.Model) { $device.Model } else { "N/A" }
            if ($device.Manufacturer -and $device.Manufacturer -ne $deviceModel) {
                $deviceModel = "$($device.Manufacturer) $deviceModel"
            }
 
            # --- Last Check-in ---
            $lastCheckIn = if ($device.ApproximateLastSignInDateTime) {
                $device.ApproximateLastSignInDateTime.ToString("yyyy-MM-dd HH:mm:ss")
            } else { "N/A" }
 
 
            $results += [PSCustomObject]@{
                DeviceName     = $device.DisplayName
                SerialNumber   = $serialNumber
                DeviceModel    = $deviceModel
                LastCheckIn    = $lastCheckIn
            }
        }
        catch {
            Write-Warning "Erreur lors de la récupération du device $($dm.Id) : $_"
        }
    }
 
    return $results
}
 
#endregion

#region --- MAIN ---

# Création du dossier de sortie
if (-not (Test-Path $OUTPUT_FOLDER)) {
    New-Item -ItemType Directory -Path $OUTPUT_FOLDER | Out-Null
    Write-Host "Dossier de sortie créé : $OUTPUT_FOLDER`n" -ForegroundColor Green
}

$totalGroups  = $COUNTRY_GROUPS.Count
$totalDevices = 0
$i = 0
$exportedFiles = @()

foreach ($entry in $COUNTRY_GROUPS.GetEnumerator()) {
    $i++
    $countryLabel = $entry.Key
    $groupId      = $entry.Value

    Write-Host "[$i/$totalGroups] Traitement du groupe : $countryLabel (ID: $groupId)" -ForegroundColor Yellow

    # Vérification que l'ID n'est pas un placeholder
    if ($groupId -like "*OBJECT-ID*") {
        Write-Host "  -> ID non renseigné, groupe ignoré." -ForegroundColor DarkGray
        continue
    }

    try {
        $devices = Get-DevicesFromGroup -GroupId $groupId -CountryLabel $countryLabel
        Write-Host "  -> $($devices.Count) appareil(s) trouvé(s)" -ForegroundColor White

        $csvFileName = "$($countryLabel -replace '[\\/:*?"<>|]', '_').csv"
        $csvPath     = Join-Path $OUTPUT_FOLDER $csvFileName

        if ($devices.Count -gt 0) {
            $devices | Sort-Object DeviceName |
                Export-Csv -Path $csvPath -Delimiter $CSV_SEPARATOR -NoTypeInformation -Encoding UTF8
            Write-Host "  -> CSV généré : $csvPath" -ForegroundColor Green
            $exportedFiles += [PSCustomObject]@{ Groupe = $countryLabel; Appareils = $devices.Count; Fichier = $csvPath }
        }
        else {
            Write-Host "  -> Aucun appareil, pas de fichier CSV généré." -ForegroundColor DarkGray
            $exportedFiles += [PSCustomObject]@{ Groupe = $countryLabel; Appareils = 0; Fichier = "(vide)" }
        }

        $totalDevices += $devices.Count
    }
    catch {
        Write-Warning "  -> Erreur sur le groupe $countryLabel : $_"
        $exportedFiles += [PSCustomObject]@{ Groupe = $countryLabel; Appareils = "ERREUR"; Fichier = "-" }
    }
}

#endregion

#region --- RÉCAPITULATIF ---

Write-Host "`n=== RÉCAPITULATIF ===" -ForegroundColor Cyan
$exportedFiles | Format-Table -AutoSize -Property Groupe, Appareils, Fichier
Write-Host "Total appareils exportés : $totalDevices" -ForegroundColor Green
Write-Host "Fichiers CSV disponibles dans : $(Resolve-Path $OUTPUT_FOLDER)`n" -ForegroundColor Green


#region --- DÉCONNEXION ---

Disconnect-MgGraph | Out-Null
Write-Host "Déconnecté de Microsoft Graph.`n" -ForegroundColor Cyan
