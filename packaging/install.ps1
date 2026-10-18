# 기본 중점 변경 모드 설치 (install.bat 이 부른다)
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$nameRe = '(?m)^\s*name\s*=\s*"([^"]*)"'
$pathRe = '(?m)^\s*path\s*=\s*"[^"]*"'

# 0) HOI4 사용자 폴더 찾기. 문서 폴더가 OneDrive 로 옮겨진 PC 가 있어 후보를 모두 본다.
$cands = New-Object System.Collections.Generic.List[string]
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs) { $cands.Add((Join-Path $docs 'Paradox Interactive\Hearts of Iron IV')) }
foreach ($root in @($env:USERPROFILE, $env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
    if (-not $root) { continue }
    foreach ($dn in @('Documents', '문서')) { $cands.Add((Join-Path $root (Join-Path $dn 'Paradox Interactive\Hearts of Iron IV'))) }
}
$cands = @($cands | Select-Object -Unique)
# 이미 new_focus 가 깔린 곳, 게임이 쓰는 곳(dlc_load.json) 을 모두 설치 대상으로 한다
$targets = @($cands | Where-Object { (Test-Path -LiteralPath (Join-Path $_ 'mod\new_focus.mod')) -or (Test-Path -LiteralPath (Join-Path $_ 'dlc_load.json')) })
if ($targets.Count -eq 0) { $targets = @($cands | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1) }
if ($targets.Count -eq 0) { $targets = @($cands[0]) }

function Install-To($hoi) {
    $d = Join-Path $hoi 'mod'
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

    # 설치 폴더 이름. 이미 new_focus 로 깔려 있으면 그 폴더를 갱신한다(런처 플레이세트가 그대로 유지된다).
    $folder = 'gibon_jungjeom'
    if (Test-Path -LiteralPath (Join-Path $d 'new_focus.mod')) { $folder = 'new_focus' }
    $outer = Join-Path $d "$folder.mod"

    $myText = [IO.File]::ReadAllText((Join-Path $src 'gibon_jungjeom.mod'), [Text.Encoding]::UTF8)
    $myText = [regex]::Replace($myText, $pathRe, "path=`"mod/$folder`"")
    if (Test-Path -LiteralPath $outer) {
        # 기존 name 을 그대로 쓴다(런처가 같은 모드로 알아본다)
        $old = [regex]::Match([IO.File]::ReadAllText($outer, [Text.Encoding]::UTF8), $nameRe)
        if ($old.Success) { $myText = [regex]::Replace($myText, $nameRe, "name=`"$($old.Groups[1].Value)`"") }
    }
    $myName = [regex]::Match($myText, $nameRe).Groups[1].Value
    $backup = Join-Path $d '_gj_backup'

    # 1) 이 모드의 예전 설치본(다른 폴더 이름)을 백업으로 옮긴다. 둘 다 켜져 있으면 예전 문구가 새 문구를 덮는다.
    foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.mod' -File) {
        if ($f.Name -eq "$folder.mod") { continue }
        $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
        $p = [regex]::Match($t, '(?m)^\s*path\s*=\s*"([^"]*)"').Groups[1].Value
        $oldDir = if ($p) { Join-Path $hoi ($p -replace '/', '\') } else { $null }
        $isOurs = $oldDir -and (Test-Path -LiteralPath $oldDir) -and
                  @(Get-ChildItem -LiteralPath $oldDir -Recurse -Filter 'gibon_jungjeom_l_*.yml' -ErrorAction SilentlyContinue).Count -gt 0
        $sameName = [regex]::Match($t, $nameRe).Groups[1].Value -eq $myName
        if ($isOurs -or $sameName) {
            New-Item -ItemType Directory -Path $backup -Force | Out-Null
            Move-Item -LiteralPath $f.FullName -Destination (Join-Path $backup $f.Name) -Force
            if ($isOurs -and ((Split-Path -Leaf $oldDir) -ne $folder)) {
                $dest = Join-Path $backup (Split-Path -Leaf $oldDir)
                if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
                Move-Item -LiteralPath $oldDir -Destination $dest -Force
            }
            Write-Host "  예전 설치본을 _gj_backup 으로 옮김: $($f.Name)"
        }
    }

    # 2) 모드 폴더를 통째로 바꾸고, .mod 두 개(폴더 옆 + 폴더 안)를 쓴다
    $t = Join-Path $d $folder
    if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
    Copy-Item -LiteralPath (Join-Path $src 'gibon_jungjeom') -Destination $t -Recurse -Force
    [IO.File]::WriteAllText($outer, $myText, $utf8NoBom)
    $inner = [regex]::Replace($myText, '(?m)^\s*path\s*=\s*"[^"]*"\r?\n?', '')
    [IO.File]::WriteAllText((Join-Path $t 'descriptor.mod'), $inner, $utf8NoBom)
    Write-Host "OK. 설치 완료: $t"
}

foreach ($hoi in $targets) { Install-To $hoi }
$ver = [regex]::Match([IO.File]::ReadAllText((Join-Path $src 'gibon_jungjeom.mod'), [Text.Encoding]::UTF8), 'version="([^"]+)"').Groups[1].Value
Write-Host ""
Write-Host "런처에서 이 모드 하나만 켜고 실행하세요. 중점에 마우스를 올리면 설명 끝에 (v$ver) 가 보여야 새 설치본입니다."
