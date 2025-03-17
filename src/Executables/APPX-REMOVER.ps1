param (
    [Parameter(Mandatory=$true)]
    [string[]]$Packages
)

$baseRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"

$allPackages = Get-AppxPackage -AllUsers | Select-Object PackageFullName, PackageFamilyName, PackageUserInformation, NonRemovable

foreach ($package in $Packages) {
    $filteredPackages = $allPackages | Where-Object { $_.PackageFullName -like "*$package*" }

    foreach ($pkg in $filteredPackages) {

        $fullPackageName = $pkg.PackageFullName
        $packageFamilyName = $pkg.PackageFamilyName

        Write-Host "Removing package: $($fullPackageName)"

        # Aggiunge la voce "Deprovisioned" per impedire l'installazione automatica durante gli aggiornamenti
        $deprovisionedPath = "$baseRegistryPath\Deprovisioned\$packageFamilyName"
        if (-not (Test-Path -Path $deprovisionedPath)) {
            New-Item -Path $deprovisionedPath -Force | Out-Null
        }

        # Rimuove la voce di "InboxApplications" se presente
        $inboxAppsPath = "$baseRegistryPath\InboxApplications\$fullPackageName"
        if (Test-Path $inboxAppsPath) {
            Remove-Item -Path $inboxAppsPath -Force
        }
        
        # Se il pacchetto è contrassegnato come non rimovibile, imposta il flag per renderlo rimovibile
        if ($pkg.NonRemovable -eq 1) {
            Set-NonRemovableAppsPolicy -Online -PackageFamilyName $packageFamilyName -NonRemovable 0
        }

        # Aggiunge il pacchetto alla chiave "EndOfLife" per ogni utente che lo ha installato
        foreach ($userInfo in $pkg.PackageUserInformation) {
            $userSid = $userInfo.UserSecurityID.SID
            $endOfLifePath = "$baseRegistryPath\EndOfLife\$userSid\$fullPackageName"
            New-Item -Path $endOfLifePath -Force | Out-Null

            # Rimuove il pacchetto per l'utente specifico
            Remove-AppxPackage -Package $fullPackageName -User $userSid
        }

        # Secondo tentativo: rimuove il pacchetto per tutti gli utenti
        Remove-AppxPackage -Package $fullPackageName -AllUsers

        # Se il pacchetto è il Microsoft Store, rimuove anche la cartella di sistema
        if ($pkg.PackageFamilyName -like "Microsoft.WindowsStore*") {
            $systemAppsPath = "C:\Windows\SystemApps\$($pkg.PackageFamilyName)"
            if (Test-Path $systemAppsPath) {
                Write-Host "Removing system folder for Microsoft Store: $systemAppsPath"
                # Prende possesso della cartella e imposta le autorizzazioni per poterla rimuovere
                takeown /F $systemAppsPath /R /D Y | Out-Null
                icacls $systemAppsPath /grant Administrators:F /T | Out-Null
                Remove-Item $systemAppsPath -Recurse -Force
            }
        }
    }
}
