# =================================================================
# Script Intune - Remediation FINALE 
# Methode : Remove-LocalGroupMember avec nom complet (Domain\User)
# Fonctionne pour : Local, AzureAD, MicrosoftAccount
# Contexte : SYSTEM
# Date : 2026-04-29
# =================================================================

$hostname = $env:COMPUTERNAME
$logFile  = "C:\ProgramData\Intune\Logs\retrograde_admins_v3.log"
New-Item -ItemType Directory -Path "C:\ProgramData\Intune\Logs" -Force | Out-Null

function Write-Log {
    param([string]$msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts | $hostname | $msg" | Add-Content -Path $logFile
}

function Retrograde-CompteLocal {
    param([string]$Compte)
    try {
        $membres = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        $cibles = $membres | Where-Object {
            ($_.Name -split "\\")[-1] -like "*$Compte*"
        }
        if ($cibles) {
            foreach ($membre in $cibles) {
                $shortName = ($membre.Name -split "\\")[-1]
                $source    = $membre.PrincipalSource
                $fullName  = $membre.Name
                Remove-LocalGroupMember -Group "Administrators" -Member $fullName -ErrorAction Stop
                Write-Log "OK  | '$shortName' [$source] retire des Administrators"
            }
        } else {
            Write-Log "SKIP| '$Compte' non present dans Administrators"
        }
    } catch {
        Write-Log "ERR | '$Compte' - $($_.Exception.Message)"
    }
}

Write-Log "=== DEBUT REMEDIATION v4 sur $hostname ==="

switch ($hostname) {
    'L-G10SCW3-CAN' {
        Retrograde-CompteLocal -Compte 'PoojaGOYAL'
        Retrograde-CompteLocal -Compte 'Pooja Goyal'
    }
    'L-66LZJL3-NLD' {
        Retrograde-CompteLocal -Compte 'JAKUBKARASINSKI'
   
    }
    'L-J885S64-ARE' {
        Retrograde-CompteLocal -Compte 'AlshaimaaGHONEMY'
    }
    'L-J0EA7TK-USA' {
        Retrograde-CompteLocal -Compte 'VadimKolchanov'
    }
    'L-F4007LF-USA' {
        Retrograde-CompteLocal -Compte 'PeytonGRAY'
    }
    'L-DLWHHL3-CAN' {
        Retrograde-CompteLocal -Compte 'AdamNICOL'
    }
    'L-F3RVV08-USA' {
        Retrograde-CompteLocal -Compte 'GretchenSTUP'
    }
    'L-8KTDC54-ARE' {
        Retrograde-CompteLocal -Compte 'S.KHAWAJA'
    }
    'L-31N6TT3-NLD' {
        Retrograde-CompteLocal -Compte 'KRUISBRINK'
    }
    'L-C1N2KNZ-USA' {
        Retrograde-CompteLocal -Compte 'JuliaJeannette'
    }
    'L-CJQPWL3-CAN' {
        Retrograde-CompteLocal -Compte 'PatriciaNeale'
    }
    'L-1HBKS64-GBR' {
        Retrograde-CompteLocal -Compte 'MiaoZHOU'
    }
    'L-F3QFVG4-USA' {
        Retrograde-CompteLocal -Compte 'AlecHenricksen'
    }
    'L-F308CA1-USA' {
        Retrograde-CompteLocal -Compte 'JessicaLIN_3lr7edb'
    }
    'L-FSZP4Y3-CAN' {
        Retrograde-CompteLocal -Compte 'KelseyLANG'
        Retrograde-CompteLocal -Compte 'Kelsey Sia Laptop'
    }
    'L-2V12FH4-GBR' {
        Retrograde-CompteLocal -Compte 'JoseFUENTEALBA'
    }
    'L-7TBKQF4-IRL' {
        Retrograde-CompteLocal -Compte 'SrishtiKAPOOR'
    }
    'L-C22P8YG-USA' {
        Retrograde-CompteLocal -Compte 'DiegoBazin'
    }
    'L-5063X3P-IND' {
        Retrograde-CompteLocal -Compte 'PoonamCHOTHANI'
    }
    'L-F3QDYR7-USA' {
        Retrograde-CompteLocal -Compte 'NarmadhaSrinivasan'
    }
    'L-G21JNL3-CAN' {
        Retrograde-CompteLocal -Compte 'MichaelaStillman'
    }
    'L-F3ZY1GM-USA' {
        Retrograde-CompteLocal -Compte 'PatrykMichon'
    }
    'L-42K0F14-NLD' {
        Retrograde-CompteLocal -Compte 'RomyHO'
    }
    'L-F1BJ8P8-USA' {
        Retrograde-CompteLocal -Compte 'ahmad.hassan'
    }
    'L-GBWB6H4-IND' {
        Retrograde-CompteLocal -Compte 'Abhisek'
    }
    'L-48JPJD4-HKG' {
        Retrograde-CompteLocal -Compte 'WassilaLAHMAR'
    }
    'L-52GK5X3-SAU' {
        Retrograde-CompteLocal -Compte 'S.Jalal'
    }
    'L-8LTDC54-SAU' {
        Retrograde-CompteLocal -Compte 'Muath MOHAMMED'
    }
    'L-3HBKS64-GBR' {
        Retrograde-CompteLocal -Compte 'FrancisHEMINGWAY'
    }
    'L-6XY4FS3-CAN' {
        Retrograde-CompteLocal -Compte 'MikhaelaAJON'
    }
    'L-52822MF-SAU' {
        Retrograde-CompteLocal -Compte 'AbdulazizALBASSAM'
    }
    'L-F3QG008-USA' {
        Retrograde-CompteLocal -Compte 'KarunakarGadireddy'
    }
    'L-5063X3X-IND' {
        Retrograde-CompteLocal -Compte 'RohitSINGH'
    }
    'L-52XYHW3-ARE' {
        Retrograde-CompteLocal -Compte 'F.Abouhassan'
    }
    'L-5063X3Y-IND' {
        Retrograde-CompteLocal -Compte 'DeepakYADAV'
    }
    'L-BTCMY84-CAN' {
        Retrograde-CompteLocal -Compte 'MyrielleROBITAILLE'
    }
    'L-F3ZZSWQ-USA' {
        Retrograde-CompteLocal -Compte 'ShriyaPrasad'
    }
    'L-28JPJD4-HKG' {
        Retrograde-CompteLocal -Compte 'LinXU'
    }
    'L-CB85S64-ARE' {
        Retrograde-CompteLocal -Compte 'OmarBATARSEH'
    }
    'L-F2208EW-USA' {
        Retrograde-CompteLocal -Compte 'jacob.mitchener'
    }
    'L-F3SVH39-USA' {
        Retrograde-CompteLocal -Compte 'PatrickDAUGHERTY'
    }
    'L-5063X3W-IND' {
        Retrograde-CompteLocal -Compte 'NarendraKUMAR'
    }
    'L-F3081TQ-USA' {
        Retrograde-CompteLocal -Compte 'ThiabultSanchez'
        Retrograde-CompteLocal -Compte 'tsanchez'
    }
    'L-6TBKQF4-IRL' {
        Retrograde-CompteLocal -Compte 'PaulGIBSON'
    }
    'L-F1BDMDU-USA' {
        Retrograde-CompteLocal -Compte 'emily.hunsperger'
    }
    'L-F4009TL-USA' {
        Retrograde-CompteLocal -Compte 'LuisCUENCA'
    }
    'L-5SGRCW3-CAN' {
        Retrograde-CompteLocal -Compte 'ZacharyMANDLOWITZ'
    }
    'L-F3VE5VC-USA' {
        Retrograde-CompteLocal -Compte 'ShariSPARLING'
    }
    'L-F26176D-USA' {
        Retrograde-CompteLocal -Compte 'IshamRekiouak'
    }
    'L-38JPJD4-HKG' {
        Retrograde-CompteLocal -Compte 'alevy'
    }
    'L-F3ZWH3V-USA' {
        Retrograde-CompteLocal -Compte 'TheoCHAMPIGNY'
    }
    'L-35L3R14-AUS' {
        Retrograde-CompteLocal -Compte 'JakeSEAWARD'
    }
    'L-F4K9HW3-ARE' {
        Retrograde-CompteLocal -Compte 'Jacques Yandem'
    }
    'L-F2GR0JT-USA' {
        Retrograde-CompteLocal -Compte 'BrettWatson'
    }
    'L-P42DY1V-USA' {
        Retrograde-CompteLocal -Compte 'LaurenSCHOUKROUN-BAR'
    }
    'L-F3DYGQL-USA' {
        Retrograde-CompteLocal -Compte 'EileenTARASCO'
    }
    'L-HHNB6H4-IND' {
        Retrograde-CompteLocal -Compte 'SwarinaPALKAR'
    }
    'L-5063X3Z-IND' {
        Retrograde-CompteLocal -Compte 'PradeepVANAHALLI'
        Retrograde-CompteLocal -Compte 'Pradeep_Sia'
    }
    'L-2TY1KD4-IRL' {
        Retrograde-CompteLocal -Compte 'FionnGEOGHEGAN'
    }
    'L-C0VNSCZ-USA' {
        Retrograde-CompteLocal -Compte 'danielle.fair'
    }
    'L-GBSBH24-BEL' {
        Retrograde-CompteLocal -Compte 'BenoitLIENART'
    }
    'L-F3G97MZ-USA' {
        Retrograde-CompteLocal -Compte 'Colin Kegel'
    }
    'L-F4009T8-USA' {
        Retrograde-CompteLocal -Compte 'NicholasDOWNS'
    }
    'L-8SXMB54-ARE' {
        Retrograde-CompteLocal -Compte 'MuhammadDAUD'
        Retrograde-CompteLocal -Compte 'M.Daud'
    }
    'L-3TY1KD4-IRL' {
        Retrograde-CompteLocal -Compte 'MattRYAN'
    }
    'L-F3TS3Z3-USA' {
        Retrograde-CompteLocal -Compte 'v-mikeryan'
    }
    'L-960C8S3-NLD' {
        Retrograde-CompteLocal -Compte 'Dennis Langelaan'
    }
    'L-3145TQ3-BEL' {
        Retrograde-CompteLocal -Compte 'jtrzcinski'
    }
    'L-1JNB6H4-IND' {
        Retrograde-CompteLocal -Compte 'MuskanCHOWATIA'
    }
    'L-D3TJQF4-NLD' {
        Retrograde-CompteLocal -Compte 'PaulaPASSET'
    }
    'L-18JPJD4-HKG' {
        Retrograde-CompteLocal -Compte 'VincentLEUNG'
    }
    'L-F2F1NAF-USA' {
        Retrograde-CompteLocal -Compte 'LenkaRASLOVA'
    }
    'L-J7JPJD4-HKG' {
        Retrograde-CompteLocal -Compte 'braguenet'
    }
    'L-79XY8G3-CAN' {
        Retrograde-CompteLocal -Compte 'JackieHUANG'
    }
    'L-8JQPWL3-CAN' {
        Retrograde-CompteLocal -Compte 'CristieSEMENIUK'
    }
    'L-F3SRR7B-USA' {
        Retrograde-CompteLocal -Compte 'RachelSCHMITZ'
    }
    'L-F4300NZ-SGP' {
        Retrograde-CompteLocal -Compte 'Kenny'
    }
    'L-9CDXN34-NLD' {
        Retrograde-CompteLocal -Compte 'FlorisWINGERDEN'
    }
    'L-F220A50-USA' {
        Retrograde-CompteLocal -Compte 'GregAngelopoulos'
    }
    'L-1V12FH4-GBR' {
        Retrograde-CompteLocal -Compte 'VikashSINGH'
    }
    'L-6ZVVHG4-ARE' {
        Retrograde-CompteLocal -Compte 'TaniaALAMEDDINE'
    }
    'L-44YY8G3-CAN' {
        Retrograde-CompteLocal -Compte 'CharlieYANG'
    }
    'L-9KH6NN3-GBR' {
        Retrograde-CompteLocal -Compte 'KaterynaKOSHEL'
    }
    'L-13CMHW3-ARE' {
        Retrograde-CompteLocal -Compte 'A.Alsaghir'
    }
    default {
        Write-Log "INFO| Poste non dans la liste ciblee - aucune action"
    }
}

Write-Log "=== FIN REMEDIATION  ==="
exit 0