# 기본 중점 변경 모드 설치 (install.bat 이 부른다)
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$d = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Hearts of Iron IV\mod'
if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

# 1) 같은 이름(name=)의 다른 .mod 를 백업 폴더로 옮긴다. 이름이 겹치면 먼저 읽힌 쪽만 쓰여 모드가 가려진다.
$myText = [IO.File]::ReadAllText((Join-Path $src 'gibon_jungjeom.mod'), [Text.Encoding]::UTF8)
$myName = [regex]::Match($myText, '(?m)^\s*name\s*=\s*"([^"]*)"').Groups[1].Value
$backup = Join-Path $d '_gj_backup'
foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.mod' -File) {
    if ($f.Name -eq 'gibon_jungjeom.mod') { continue }
    $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    if ([regex]::Match($t, '(?m)^\s*name\s*=\s*"([^"]*)"').Groups[1].Value -eq $myName) {
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Move-Item -LiteralPath $f.FullName -Destination (Join-Path $backup $f.Name) -Force
        Write-Host "Moved duplicate descriptor to _gj_backup: $($f.Name)"
    }
}

# 2) 모드 폴더와 바깥 .mod 를 복사한다
$t = Join-Path $d 'gibon_jungjeom'
if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $src 'gibon_jungjeom') -Destination $d -Recurse -Force
Copy-Item -LiteralPath (Join-Path $src 'gibon_jungjeom.mod') -Destination $d -Force
Write-Host "OK. Installed to: $d"
Write-Host "Open the launcher, enable only this mod in the playset, then press Play."
