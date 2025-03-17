Write-Host 'Updating Microsoft Store apps...'
# Write-Host 'Installing Winget Source'
# Add-AppPackage 'https://cdn.winget.microsoft.com/cache/source.msix' -ForceApplicationShutdown -Verbose
$productName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName
Write-Host "Product Name: $productName"

$argumentsList = if ($productName -like '*LTSC*') {'msstore-apps --id 9NBLGGH4NNS1 --ring RP'} else {'msstore-apps --id 9WZDNCRFJBMP --id 9NBLGGH4NNS1 --ring RP'}
Start-Process -FilePath $file -ArgumentList $argumentsList -Wait -NoNewWindow -PassThru -Verbose

$programDataPath = [System.Environment]::GetFolderPath('CommonApplicationData')
$appDataPath = [System.Environment]::GetFolderPath('ApplicationData')
$programsPath = Join-Path $appDataPath "Microsoft\Windows\Start Menu\Programs"
$systemToolsPath = Join-Path $programsPath "System Tools"

$foldersToHide = @(
    "Accessibility",
    "Administrative Tools.lnk",
    "Windows PowerShell",
    "Accessories",
    "System Tools",
    "Administrative Tools"
)

$fileExplorerShortcut = Join-Path $systemToolsPath "File Explorer.lnk"
$newLocation = Join-Path $programsPath "File Explorer.lnk"

if (Test-Path $fileExplorerShortcut) {
    Move-Item -Path $fileExplorerShortcut -Destination $newLocation -Force
    Write-Host "Moved File Explorer shortcut to: $newLocation"
} else {
    Write-Host "File Explorer shortcut not found in System Tools."
}

function Hide-ItemRecursively {
    param (
        [string]$Path
    )

    if (Test-Path $Path) {
        Write-Host "Hiding: $Path"

        $dirItem = Get-Item $Path -Force
        $dirItem.Attributes = $dirItem.Attributes -bor [System.IO.FileAttributes]::Hidden

        Get-ChildItem $Path -Recurse -Force | ForEach-Object {
            $_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::Hidden
        }

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c attrib +h +s `"$Path`" /s /d" -Wait -NoNewWindow
    }
    else {
        Write-Host "Not found: $Path"
    }
}

foreach ($folderName in $foldersToHide) {
    $fullPath = Join-Path $programsPath $folderName
    Hide-ItemRecursively -Path $fullPath
}
