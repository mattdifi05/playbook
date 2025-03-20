$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer";
        $regName = "SettingsPageVisibility";
        $newValue = "windowsdefender;";
        if (Test-Path $regPath) {
            $currentValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName;
            if ($currentValue -match $newValue) {
            } else {
                if ($currentValue) {
                    $updatedValue = "$currentValue$newValue";
                } else {
                    $updatedValue = $newValue;
                }
                Set-ItemProperty -Path $regPath -Name $regName -Value $updatedValue;
            }
        } else {
            New-Item -Path $regPath -Force | Out-Null;
            Set-ItemProperty -Path $regPath -Name $regName -Value $newValue;
        }