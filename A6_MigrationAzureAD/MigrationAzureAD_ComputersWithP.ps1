#################################### LOGIN GRAPH ####################################
$headers = @{"Content-Type" = "application/x-www-form-urlencoded" }
$body = @{
    client_id     = ""
    scope         = ""
    client_secret = ""
    grant_type    = ""
}
$auth = (Invoke-WebRequest -Uri "https://login.microsoftonline.com/tenant/oauth2/v2.0/token" -Method POST -Headers $headers -Body $body).Content | ConvertFrom-Json
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
# Définir le chemin du fichier CSV d'entrée
$inputCsvPath = "AzureAD/intune/migration_ad/users_check.csv"
# Définir le chemin du fichier CSV de sortie
$outputCsvPath = "AzureAD/intune/migration_ad/log/export_devices_users_precedence.csv"

# Lire le fichier CSV contenant les UserPrincipalName
$users = Import-Csv -Path $inputCsvPath

# Liste pour stocker les résultats
$output = @()

# Traiter chaque utilisateur
foreach ($user in $users) {
    $upn = $user.UserPrincipalName

    Write-Host "Traitement de l'utilisateur : $upn"

    # Récupérer l'utilisateur Azure AD
    $userData = Get-MgUser -UserId $upn -Property Id, DisplayName -ErrorAction SilentlyContinue
    if (-not $userData) {
        Write-Host " Utilisateur non trouvé : $upn"
        $output += [PSCustomObject]@{
            UserPrincipalName      = $upn
            DeviceName             = "User non found"
            OperatingSystem        = ""
            Model                  = ""
            ComplianceState        = ""
            LastSyncDateTime       = ""
            AzureADDeviceId        = ""
            JoinType               = ""
            PrimaryUserDisplayName = ""
            PrimaryUserUPN         = ""
            OnPremisesSyncEnabled  = ""
            OnPremisesImmutableId  = ""
            CustomAttribute9       = ""
            CustomAttribute1       = ""
            CustomAttribute7       = ""
            CustomAttribute8       = ""
        }
        continue
    }

    # Récupérer les appareils enregistrés pour cet utilisateur
    $devices = Get-MgUserRegisteredDevice -UserId $userData.Id

    if (-not $devices) {
        Write-Host "Aucun appareil trouvé pour : $upn"
        $output += [PSCustomObject]@{
            UserPrincipalName      = $upn
            DeviceName             = "device not found"
            OperatingSystem        = ""
            Model                  = ""
            ComplianceState        = ""
            LastSyncDateTime       = ""
            AzureADDeviceId        = ""
            JoinType               = ""
            PrimaryUserDisplayName = ""
            PrimaryUserUPN         = ""
            OnPremisesSyncEnabled  = ""
            OnPremisesImmutableId  = ""
            CustomAttribute9       = ""
            CustomAttribute1       = ""
            CustomAttribute7       = ""
            CustomAttribute8       = ""
        }
        continue
    }

    # Récupérer les informations des appareils
    $devices | ForEach-Object {
        $deviceId = $_.Id
        $deviceDetails = Get-MgDevice -DeviceId $deviceId -Property DisplayName, OperatingSystem, Model, IsCompliant, ApproximateLastSignInDateTime, DeviceId, TrustType
        $joinType = if ($deviceDetails.TrustType) { $deviceDetails.TrustType } else { "Unknown" }

        $primaryUser = Get-MgDeviceRegisteredOwner -DeviceId $deviceId | Select-Object -ExpandProperty Id
        if ($primaryUser) {
            $userInfo = Get-MgUser -UserId $primaryUser -Property DisplayName, UserPrincipalName, OnPremisesSyncEnabled, OnPremisesImmutableId, OnPremisesExtensionAttributes
        } else {
            $userInfo = $null
        }

        $output += [PSCustomObject]@{
            UserPrincipalName      = $upn
            DeviceName             = $deviceDetails.DisplayName
            OperatingSystem        = $deviceDetails.OperatingSystem
            Model                  = $deviceDetails.Model
            ComplianceState        = if ($deviceDetails.IsCompliant) { "Compliant" } else { "Non-Compliant" }
            LastSyncDateTime       = $deviceDetails.ApproximateLastSignInDateTime
            AzureADDeviceId        = $deviceDetails.DeviceId
            JoinType               = $joinType
            PrimaryUserDisplayName = $userInfo.DisplayName
            PrimaryUserUPN         = $userInfo.UserPrincipalName
            OnPremisesSyncEnabled  = $userInfo.OnPremisesSyncEnabled
            OnPremisesImmutableId  = $userInfo.OnPremisesImmutableId
            CustomAttribute9       = $userInfo.OnPremisesExtensionAttributes.ExtensionAttribute9
            CustomAttribute1       = $userInfo.OnPremisesExtensionAttributes.ExtensionAttribute1
            CustomAttribute7       = $userInfo.OnPremisesExtensionAttributes.ExtensionAttribute7
            CustomAttribute8       = $userInfo.OnPremisesExtensionAttributes.ExtensionAttribute8
        }
    }
}

#  Grouper par UserPrincipalName et appliquer la logique de sélection prioritaire
$finalOutput = $output | Group-Object UserPrincipalName | ForEach-Object {
    $userGroup = $_.Group

    #  Priorité 1 : Devices ServerAd ou AzureAd
    $priorityDevices = $userGroup | Where-Object { $_.JoinType -in @("ServerAd", "AzureAd") }

    if ($priorityDevices) {
        $selected = $priorityDevices | Sort-Object {
            try { Get-Date -Date $_.LastSyncDateTime }
            catch { [datetime]::MinValue }
        } -Descending | Select-Object -First 1
    } else {
        #  Priorité 2 : Workgroup mais uniquement si OS est Windows, MacOS, Mac, MacMDM ou Linux
        $workgroupDevices = $userGroup | Where-Object { 
            $_.JoinType -eq "Workgroup" -and 
            ($_.OperatingSystem -match "windows|macos|macmdm|mac|linux")
        }

        if ($workgroupDevices) {
            $selected = $workgroupDevices | Sort-Object {
                try { Get-Date -Date $_.LastSyncDateTime }
                catch { [datetime]::MinValue }
            } -Descending | Select-Object -First 1
        } else {
            # Fallback si vraiment rien de ce qui précède
            $selected = $userGroup | Sort-Object {
                try { Get-Date -Date $_.LastSyncDateTime }
                catch { [datetime]::MinValue }
            } -Descending | Select-Object -First 1
        }
    }

    $selected
}

#  Exporter les données filtrées
$finalOutput | Export-Csv -Path $outputCsvPath -NoTypeInformation -Delimiter "," -Encoding utf8

Write-Host " Export terminé avec la logique de priorité JoinType et OS : $outputCsvPath"

 
