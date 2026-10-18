<#
    기본 중점 변경 모드 — PC 상태 보고서

        powershell -ExecutionPolicy Bypass -File .\tools\Report-ModState.ps1

    저장소 맨 위에 reports\mod-state.txt 를 만든다. 아무것도 고치지 않고 읽기만 한다.
    모드 폴더 목록, .mod 의 name/path/version, 런처에서 켜진 모드(dlc_load.json),
    _gj_backup 내용, 옛 문구("설계 효과") 남은 곳, error.log 의 관련 줄을 모은다.
#>
$ErrorActionPreference = 'Continue'
# 저장소(tools\)에서 돌리면 reports\mod-state.txt, zip 에서 돌리면 같은 폴더의 mod-state.txt 에 쓴다
$repo = Split-Path -Parent $PSScriptRoot
$srcMod = Join-Path $repo 'mod\gibon_jungjeom.mod'
if (Test-Path -LiteralPath $srcMod) {
    $outDir = Join-Path $repo 'reports'
} else {
    $srcMod = Join-Path $PSScriptRoot 'gibon_jungjeom.mod'
    $outDir = $PSScriptRoot
}
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$out = Join-Path $outDir 'mod-state.txt'
$lines = New-Object System.Collections.Generic.List[string]
function L($s) { $lines.Add([string]$s) }
function Resolve-ModDir($hoi, $p) {
    # .mod 의 path 는 "mod/xxx" 처럼 상대일 수도, 런처가 쓴 "C:/Users/.../mod/xxx" 처럼 절대일 수도 있다
    if (-not $p) { return '' }
    # 윈도우는 / 와 \ 를 모두 받는다. 판별만 하고 문자열은 그대로 쓴다
    if ([IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $hoi $p)
}



L "# 기본 중점 변경 모드 PC 상태 ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
$want = if (Test-Path -LiteralPath $srcMod) { [regex]::Match((Get-Content -LiteralPath $srcMod -Raw -Encoding UTF8), 'version="([^"]+)"').Groups[1].Value } else { '?' }
L "설치 파일 버전: $want"

$cands = New-Object System.Collections.Generic.List[string]
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs) { $cands.Add((Join-Path $docs 'Paradox Interactive\Hearts of Iron IV')) }
foreach ($root in @($env:USERPROFILE, $env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
    if (-not $root) { continue }
    foreach ($dn in @('Documents', '문서')) { $cands.Add((Join-Path $root (Join-Path $dn 'Paradox Interactive\Hearts of Iron IV'))) }
}
foreach ($hoi in @($cands | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $hoi)) { continue }
    L ""; L "## $hoi"
    $dlc = Join-Path $hoi 'dlc_load.json'
    if (Test-Path -LiteralPath $dlc) {
        try { $en = @((Get-Content -LiteralPath $dlc -Raw -Encoding UTF8 | ConvertFrom-Json).enabled_mods) } catch { $en = @('(읽기 실패)') }
        L "켜진 모드(dlc_load.json): $($en -join ', ')"
    } else { L "dlc_load.json 없음" }
    $d = Join-Path $hoi 'mod'
    if (-not (Test-Path -LiteralPath $d)) { L "mod 폴더 없음"; continue }
    L "### .mod 파일"
    foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.mod' -File) {
        $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
        $name = [regex]::Match($t, '(?m)^\s*name\s*=\s*"([^"]*)"').Groups[1].Value
        $path = [regex]::Match($t, '(?m)^\s*path\s*=\s*"([^"]*)"').Groups[1].Value
        $ver = [regex]::Match($t, 'version="([^"]+)"').Groups[1].Value
        $dir = Resolve-ModDir $hoi $path
        $exists = $dir -and (Test-Path -LiteralPath $dir)
        $ours = $exists -and @(Get-ChildItem -LiteralPath $dir -Recurse -Filter 'gibon_jungjeom_l_*.yml' -ErrorAction SilentlyContinue).Count -gt 0
        $old = $ours -and @(Select-String -Path (Join-Path $dir 'localisation\*\*.yml') -Pattern '설계 효과' -List -ErrorAction SilentlyContinue).Count -gt 0
        L "- $($f.Name) | name=$name | path=$path | version=$ver | 폴더있음=$exists | 이모드=$ours | 옛문구=$old"
    }
    $bk = Join-Path $d '_gj_backup'
    if (Test-Path -LiteralPath $bk) { L "### _gj_backup: $((Get-ChildItem -LiteralPath $bk | ForEach-Object Name) -join ', ')" }
    $log = Join-Path $hoi 'logs\error.log'
    if (Test-Path -LiteralPath $log) {
        L "### error.log 관련 줄 (최대 80)"
        Select-String -LiteralPath $log -Pattern 'GJ_|gibon|generic_focus|new_focus' | Select-Object -First 80 | ForEach-Object { L $_.Line }
    }
    $glog = Join-Path $hoi 'logs\game.log'
    if (Test-Path -LiteralPath $glog) {
        L "### game.log 모드 줄"
        Select-String -LiteralPath $glog -Pattern 'Active Mod|mod/' | Select-Object -First 20 | ForEach-Object { L $_.Line }
    }
}
[IO.File]::WriteAllLines($out, $lines, (New-Object Text.UTF8Encoding($false)))
Write-Host "작성: $out"
Write-Host "이 파일 내용을 그대로 복사해서 채팅에 붙여 주세요."
