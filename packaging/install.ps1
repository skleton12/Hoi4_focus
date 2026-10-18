# 기본 중점 변경 모드 설치 (install.bat 이 부른다)
# 원칙: 아무것도 지우거나 치우지 않는다. 이 모드가 깔린 폴더는 모두 새 내용으로 갱신한다.
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
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
    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
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
            if (Test-Path -LiteralPath $dest) { continue }
            $p = [regex]::Match([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8), $pathRe).Groups[1].Value
            $leaf = if ($p) { Split-Path -Leaf ($p -replace '/', '\') } else { '' }
            $bdir = if ($leaf) { Join-Path $backup $leaf } else { '' }
            $odir = if ($leaf) { Join-Path $d $leaf } else { '' }
            if ($bdir -and (Test-Path -LiteralPath $bdir) -and -not (Test-Path -LiteralPath $odir)) {
                Move-Item -LiteralPath $bdir -Destination $odir
            }
            Move-Item -LiteralPath $f.FullName -Destination $dest
            Write-Host "  되돌림: $($f.Name)"
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
