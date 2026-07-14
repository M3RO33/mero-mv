param([switch]$CheckOnly)

# ============================================================
#  MERO 포폴 업데이터 - 자동 설치기
#  Git / GitHub CLI 자동 설치 + 저장소 다운로드 + 바로가기 생성
# ============================================================

$repoUrl   = 'https://github.com/M3RO33/mero-mv.git'
$targetDir = Join-Path $env:USERPROFILE 'mero-mv'

function Say($m, $c = 'Gray') { Write-Host "  $m" -ForegroundColor $c }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Refresh-Path {
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

Write-Host ""
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host "   🍈 MERO 포폴 업데이터 설치" -ForegroundColor Green
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host ""

$hasWinget = Have winget
if (-not $hasWinget -and -not (Have git) -and -not $CheckOnly) {
  Say "이 PC에 winget(앱 설치 도구)이 없어요." Red
  Say "Windows를 최신으로 업데이트하거나, git-scm.com 에서 Git을 직접 설치한 뒤 다시 실행해 주세요." Yellow
  return
}

# ---------- 1) Git ----------
if (Have git) {
  Say "① Git ......... 이미 설치됨 ✓" Green
} elseif ($CheckOnly) {
  Say "① Git ......... 설치 예정" Yellow
} else {
  Say "① Git 설치 중... (설치 허용 창이 뜨면 '예'를 눌러주세요)" Cyan
  winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
  Refresh-Path
  if (Have git) { Say "   Git 설치 완료 ✓" Green } else { Say "   Git 설치를 확인하지 못했어요. PC를 재시작 후 다시 시도해 주세요." Red; return }
}

# ---------- 2) GitHub CLI ----------
if (Have gh) {
  Say "② GitHub CLI .. 이미 설치됨 ✓" Green
} elseif ($CheckOnly) {
  Say "② GitHub CLI .. 설치 예정" Yellow
} else {
  Say "② GitHub CLI 설치 중... (설치 허용 창이 뜨면 '예')" Cyan
  winget install --id GitHub.cli -e --source winget --accept-source-agreements --accept-package-agreements
  Refresh-Path
  if (Have gh) { Say "   GitHub CLI 설치 완료 ✓" Green } else { Say "   GitHub CLI 설치를 확인하지 못했어요. PC 재시작 후 다시 시도해 주세요." Red; return }
}

# ---------- 3) GitHub 로그인 ----------
$loggedIn = $false
if (Have gh) {
  gh auth status *> $null
  $loggedIn = ($LASTEXITCODE -eq 0)
}
if ($loggedIn) {
  Say "③ GitHub 로그인  이미 되어 있음 ✓" Green
} elseif ($CheckOnly) {
  Say "③ GitHub 로그인  필요 (브라우저에서 승인 예정)" Yellow
} else {
  Say "③ GitHub 로그인 — 잠시 후 안내에 따라 브라우저에서 승인해 주세요" Cyan
  Say "   (화면의 XXXX-XXXX 코드를 브라우저에 입력 → Authorize)" Gray
  Write-Host ""
  gh auth login --hostname github.com --git-protocol https --web
  gh auth status *> $null
  if ($LASTEXITCODE -ne 0) { Say "   로그인이 완료되지 않았어요. 다시 실행해 주세요." Red; return }
  Say "   로그인 완료 ✓" Green
}

# ---------- 4) 저장소 다운로드 ----------
if ($CheckOnly) {
  Say "④ 저장소 ....... $targetDir 에 내려받을 예정" Yellow
  Say ""
  Say "(CheckOnly: 실제 설치는 하지 않았어요)" Yellow
  return
}

if (Test-Path (Join-Path $targetDir '.git')) {
  Say "④ 저장소 최신화 중..." Cyan
  Push-Location $targetDir
  git fetch origin 2>&1 | Out-Null
  git reset --hard origin/main 2>&1 | Out-Null
  Pop-Location
} else {
  Say "④ 저장소 다운로드 중... ($targetDir)" Cyan
  git clone --quiet $repoUrl $targetDir
}
if (-not (Test-Path (Join-Path $targetDir 'index.html'))) {
  Say "   다운로드에 실패했어요. 인터넷/로그인 상태를 확인한 뒤 다시 실행해 주세요." Red
  return
}
Say "   완료 ✓" Green

# ---------- 5) 바탕화면 바로가기 ----------
$vbs = Join-Path $targetDir 'MERO 업데이트.vbs'
try {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $lnkPath = Join-Path $desktop 'MERO 포폴 업데이트.lnk'
  $sh = New-Object -ComObject WScript.Shell
  $lnk = $sh.CreateShortcut($lnkPath)
  $lnk.TargetPath = 'wscript.exe'
  $lnk.Arguments = "`"$vbs`""
  $lnk.WorkingDirectory = $targetDir
  $lnk.IconLocation = 'shell32.dll,43'
  $lnk.Save()
  Say "⑤ 바탕화면에 'MERO 포폴 업데이트' 바로가기 생성 ✓" Green
} catch {
  Say "⑤ 바로가기 생성은 건너뜀 (폴더에서 직접 실행하면 돼요)" Yellow
}

Write-Host ""
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host "   🎉 설치 완료! 이제 바탕화면의" -ForegroundColor Green
Write-Host "   'MERO 포폴 업데이트'를 더블클릭하면 앱이 열려요." -ForegroundColor Green
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host ""
