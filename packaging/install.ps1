# 기본 중점 변경 모드 설치 (install.bat 이 부른다)
# 하는 일 (정확히):
#  - 이 모드가 깔린 폴더(gibon_jungjeom, new_focus 등)마다, 먼저 지금 내용을 mod\_gj_backup\<폴더>_<시각> 에 복사해 두고
#    폴더 내용을 새 버전으로 바꾼다. .mod 의 name·path 는 그대로 둔다(런처 플레이세트 유지).
#  - 0.4.7 이 mod\_gj_backup 으로 옮긴 이 모드의 .mod·폴더는 원래 자리에 없을 때만 되돌린다.
#  - 다른 모드는 건드리지 않는다. 런처에서 켜진 .mod 를 옮기거나 지우지 않는다.
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
# 저장소에서 바로 돌릴 때(packaging\install.ps1)는 mod 폴더를 소스로 쓴다
if (-not (Test-Path -LiteralPath (Join-Path $src 'gibon_jungjeom.mod'))) { $src = Join-Path (Split-Path -Parent $PSScriptRoot) 'mod' }
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$nameRe = '(?m)^\s*name\s*=\s*"([^"]*)"'
$pathRe = '(?m)^\s*path\s*=\s*"([^"]*)"'
$srcText = [IO.File]::ReadAllText((Join-Path $src 'gibon_jungjeom.mod'), [Text.Encoding]::UTF8)
$ver = [regex]::Match($srcText, 'version="([^"]+)"').Groups[1].Value

# HOI4 사용자 폴더 후보 (문서 폴더가 OneDrive 로 옮겨진 PC 포함)
$cands = New-Object System.Collections.Generic.List[string]
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs) { $cands.Add((Join-Path $docs 'Paradox Interactive\Hearts of Iron IV')) }
foreach ($root in @($env:USERPROFILE, $env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
    if (-not $root) { continue }
    foreach ($dn in @('Documents', '문서')) { $cands.Add((Join-Path $root (Join-Path $dn 'Paradox Interactive\Hearts of Iron IV'))) }
}
$cands = @($cands | Select-Object -Unique | Where-Object { Test-Path -LiteralPath $_ })
if ($cands.Count -eq 0) { throw "HOI4 문서 폴더를 찾지 못했습니다. 게임을 한 번 실행한 뒤 다시 해 주세요." }

function Is-Ours($dir) {
    (Test-Path -LiteralPath $dir) -and
    @(Get-ChildItem -LiteralPath $dir -Recurse -Filter 'gibon_jungjeom_l_*.yml' -ErrorAction SilentlyContinue).Count -gt 0
}

function Update-Copy($hoi, $modFile) {
    # 기존 .mod 의 name·path 를 그대로 두고 내용과 버전만 바꾼다(런처 플레이세트가 그대로 유지된다)
    $old = [IO.File]::ReadAllText($modFile, [Text.Encoding]::UTF8)
    $name = [regex]::Match($old, $nameRe).Groups[1].Value
    $path = [regex]::Match($old, $pathRe).Groups[1].Value
    $dir = Join-Path $hoi ($path -replace '/', '\')
    if (Test-Path -LiteralPath $dir) {
        # 지우기 전에 지금 내용을 복사해 둔다(백업 폴더에는 .mod 가 없어 게임이 읽지 않는다)
        $bk = Join-Path (Join-Path $hoi 'mod\_gj_backup') ((Split-Path -Leaf $dir) + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
        New-Item -ItemType Directory -Path (Split-Path -Parent $bk) -Force | Out-Null
        Copy-Item -LiteralPath $dir -Destination $bk -Recurse -Force
        Remove-Item -LiteralPath $dir -Recurse -Force
        Write-Host "  이전 내용 백업: $bk"
    }
    Copy-Item -LiteralPath (Join-Path $src 'gibon_jungjeom') -Destination $dir -Recurse -Force
    $text = [regex]::Replace($srcText, '(?m)^\s*path\s*=\s*"[^"]*"', "path=`"$path`"")
    if ($name) { $text = [regex]::Replace($text, '(?m)^\s*name\s*=\s*"[^"]*"', "name=`"$name`"") }
    [IO.File]::WriteAllText($modFile, $text, $utf8NoBom)
    $inner = [regex]::Replace($text, '(?m)^\s*path\s*=\s*"[^"]*"\r?\n?', '')
    [IO.File]::WriteAllText((Join-Path $dir 'descriptor.mod'), $inner, $utf8NoBom)
    Write-Host "  갱신: $dir  ($name)"
}

foreach ($hoi in $cands) {
    $d = Join-Path $hoi 'mod'
    if (-not (Test-Path -LiteralPath $d)) { continue }

    # 1) 0.4.7 이 _gj_backup 으로 옮긴 이 모드의 설치본을 원래 자리로 되돌린다
    $backup = Join-Path $d '_gj_backup'
    if (Test-Path -LiteralPath $backup) {
        foreach ($f in Get-ChildItem -LiteralPath $backup -Filter '*.mod' -File) {
            $dest = Join-Path $d $f.Name
            $p = [regex]::Match([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8), $pathRe).Groups[1].Value
            $leaf = if ($p) { Split-Path -Leaf ($p -replace '/', '\') } else { '' }
            $bdir = if ($leaf) { Join-Path $backup $leaf } else { '' }
            $odir = if ($leaf) { Join-Path $d $leaf } else { '' }
            if (-not ($bdir -and (Is-Ours $bdir))) { continue }   # 이 모드가 아닌 것은 건드리지 않는다
            # 폴더와 .mod 를 각각, 원래 자리에 없을 때만 되돌린다
            if (-not (Test-Path -LiteralPath $odir)) { Move-Item -LiteralPath $bdir -Destination $odir; Write-Host "  되돌림: $leaf\" }
            if (-not (Test-Path -LiteralPath $dest)) { Move-Item -LiteralPath $f.FullName -Destination $dest; Write-Host "  되돌림: $($f.Name)" }
        }
    }

    # 2) 이 모드가 깔린 모든 폴더를 갱신한다
    $mine = @()
    foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.mod' -File) {
        $p = [regex]::Match([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8), $pathRe).Groups[1].Value
        if (-not $p) { continue }
        $dir = Join-Path $hoi ($p -replace '/', '\')
        if ((Is-Ours $dir) -or $f.Name -in @('gibon_jungjeom.mod', 'new_focus.mod')) { $mine += $f.FullName }
    }
    if ($mine.Count -gt 0) {
        Write-Host "[$hoi]"
        foreach ($m in $mine) { Update-Copy $hoi $m }
    }
}

# 3) 어디에도 없으면 새로 깐다 (게임이 쓰는 폴더 = dlc_load.json 이 있는 곳)
$any = $false
foreach ($hoi in $cands) {
    foreach ($f in Get-ChildItem -LiteralPath (Join-Path $hoi 'mod') -Filter '*.mod' -File -ErrorAction SilentlyContinue) {
        if (Is-Ours (Join-Path $hoi ('mod\' + [IO.Path]::GetFileNameWithoutExtension($f.Name)))) { $any = $true }
    }
}
if (-not $any) {
    $hoi = @($cands | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'dlc_load.json') }) + $cands | Select-Object -First 1
    $d = Join-Path $hoi 'mod'
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    $modFile = Join-Path $d 'gibon_jungjeom.mod'
    [IO.File]::WriteAllText($modFile, $srcText, $utf8NoBom)
    Update-Copy $hoi $modFile
}

Write-Host ""
Write-Host "완료 (v$ver). 런처 플레이세트에서 '기본 중점 변경 모드' 가 켜져 있는지 확인하고 실행하세요."
Write-Host "중점에 마우스를 올리면 설명 끝에 (v$ver) 가 보여야 합니다."
