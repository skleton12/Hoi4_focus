# 기본 중점 변경 모드 설치 (install.bat 이 부른다)
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$d = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Hearts of Iron IV\mod'
if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

# 0) 설치 폴더 이름. 이미 new_focus 로 깔려 있으면 그 폴더를 갱신한다(런처 플레이세트가 그대로 유지된다).
$folder = 'gibon_jungjeom'
if (Test-Path -LiteralPath (Join-Path $d 'new_focus.mod')) { $folder = 'new_focus' }
$outer = Join-Path $d "$folder.mod"

$myText = [IO.File]::ReadAllText((Join-Path $src 'gibon_jungjeom.mod'), [Text.Encoding]::UTF8)
$myText = [regex]::Replace($myText, '(?m)^\s*path\s*=\s*"[^"]*"', "path=`"mod/$folder`"")
if (Test-Path -LiteralPath $outer) {
    # 기존 name 을 그대로 쓴다(런처가 같은 모드로 알아본다)
    $old = [regex]::Match([IO.File]::ReadAllText($outer, [Text.Encoding]::UTF8), '(?m)^\s*name\s*=\s*"([^"]*)"')
    if ($old.Success) { $myText = [regex]::Replace($myText, '(?m)^\s*name\s*=\s*"[^"]*"', "name=`"$($old.Groups[1].Value)`"") }
}
$myName = [regex]::Match($myText, '(?m)^\s*name\s*=\s*"([^"]*)"').Groups[1].Value

# 1) 같은 이름(name=)의 다른 .mod 를 백업 폴더로 옮긴다. 이름이 겹치면 먼저 읽힌 쪽만 쓰여 모드가 가려진다.
$backup = Join-Path $d '_gj_backup'
foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.mod' -File) {
    if ($f.Name -eq "$folder.mod") { continue }
    $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    if ([regex]::Match($t, '(?m)^\s*name\s*=\s*"([^"]*)"').Groups[1].Value -eq $myName) {
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Move-Item -LiteralPath $f.FullName -Destination (Join-Path $backup $f.Name) -Force
        Write-Host "Moved duplicate descriptor to _gj_backup: $($f.Name)"
    }
}

# 2) 모드 폴더를 통째로 바꾸고, .mod 두 개(폴더 옆 + 폴더 안)를 쓴다
$t = Join-Path $d $folder
if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $src 'gibon_jungjeom') -Destination $t -Recurse -Force
$utf8NoBom = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText($outer, $myText, $utf8NoBom)
$inner = [regex]::Replace($myText, '(?m)^\s*path\s*=\s*"[^"]*"\r?\n?', '')
[IO.File]::WriteAllText((Join-Path $t 'descriptor.mod'), $inner, $utf8NoBom)
Write-Host "OK. Installed to: $t"
Write-Host "Open the launcher, enable only this mod in the playset, then press Play."
