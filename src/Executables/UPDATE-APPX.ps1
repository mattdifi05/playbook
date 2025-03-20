Write-Host 'Updating Microsoft Store apps...'
# Write-Host 'Installing Winget Source'
# Add-AppPackage 'https://cdn.winget.microsoft.com/cache/source.msix' -ForceApplicationShutdown -Verbose
$productName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName
Write-Host "Product Name: $productName"

$argumentsList = if ($productName -like '*LTSC*') {'msstore-apps --id 9NBLGGH4NNS1 --ring RP'} else {'msstore-apps --id 9WZDNCRFJBMP --id 9NBLGGH4NNS1 --ring RP'}
Start-Process -FilePath $file -ArgumentList $argumentsList -Wait -NoNewWindow -PassThru -Verbose

$source = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk"
$destination = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\"

if (Test-Path $source) {
    Move-Item -Path $source -Destination $destination -Force
    Write-Host "Il file è stato spostato con successo."
} else {
    Write-Host "Il file non esiste nel percorso sorgente."
}

$programsPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs"
)

$foldersToHide = @(
    "Accessibility",
    "Administrative Tools.lnk",
    "Windows PowerShell",
    "Accessories",
    "System Tools",
    "Administrative Tools",
    "Windows PowerShell",
    "Administrative Tools",
    "System Tools",
    "Accessories",
    "Accessibility"
)


foreach ($programsPath in $programsPaths) {
    foreach ($folderName in $foldersToHide) {
        $fullPath = Join-Path $programsPath $folderName
        
        if (Test-Path $fullPath) {
            Write-Host "Hiding: $fullPath"
            
            $dirItem = Get-Item $fullPath
            $dirItem.Attributes = $dirItem.Attributes -bor [System.IO.FileAttributes]::Hidden
            
            Get-ChildItem $fullPath -Recurse -Force | ForEach-Object {
                $_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::Hidden
            }
        }
        else {
            Write-Host "Not found: $fullPath"
        }
    }
}