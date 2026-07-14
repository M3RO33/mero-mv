# MERO 포트폴리오 원터치 업데이트
# 사용법: 사이트 편집 모드 > "목록 내보내기" 클릭(복사됨) > 이 스크립트 실행
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $here 'index.html'

function Fail($msg) {
  Write-Host ""
  Write-Host "  [X] $msg" -ForegroundColor Red
  Write-Host ""
  exit 1
}

Write-Host ""
Write-Host "  ==============================================="
Write-Host "   MERO 포트폴리오 업데이트" -ForegroundColor Green
Write-Host "  ==============================================="
Write-Host ""

# 1) 클립보드에서 목록(JSON) 읽기
$clip = Get-Clipboard -Raw
if ([string]::IsNullOrWhiteSpace($clip)) {
  Fail "클립보드가 비어 있어요. 사이트 편집 모드에서 '목록 내보내기'를 먼저 눌러주세요!"
}

try {
  $data = $clip | ConvertFrom-Json
} catch {
  Fail "복사된 내용이 올바른 목록 형식이 아니에요. '목록 내보내기'를 다시 눌러 복사한 뒤 실행해 주세요."
}

if ($data -isnot [System.Array]) { $data = @($data) }
if ($data.Count -eq 0) { Fail "목록이 비어 있어요." }
foreach ($item in $data) {
  if (-not $item.id -or -not $item.title) {
    Fail "목록 항목에 id 또는 title이 없어요. '목록 내보내기'로 복사한 내용인지 확인해 주세요."
  }
}

Write-Host "  영상 $($data.Count)개를 읽었어요:" -ForegroundColor Green
$i = 1
foreach ($item in $data) {
  Write-Host ("    {0,2}. {1}" -f $i, $item.title)
  $i++
}
Write-Host ""

# 2) SEED_VIDEOS 배열 새로 만들기 (제목은 \와 " 만 이스케이프)
$lines = foreach ($item in $data) {
  $t = ([string]$item.title) -replace '\\', '\\' -replace '"', '\"'
  '  { "id": "' + $item.id + '", "title": "' + $t + '" }'
}
$body = $lines -join ",`n"
$newBlock = "const SEED_VIDEOS = [`n$body`n];"

# 3) index.html 안의 SEED_VIDEOS 교체
$content = [System.IO.File]::ReadAllText($indexPath)
$rx = [regex]'(?s)const SEED_VIDEOS = \[.*?\];'
if (-not $rx.IsMatch($content)) { Fail "index.html에서 목록 위치를 못 찾았어요. (SEED_VIDEOS)" }
$content = $rx.Replace($content, { param($m) $newBlock }, 1)
[System.IO.File]::WriteAllText($indexPath, $content, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "  [OK] index.html 반영 완료" -ForegroundColor Green

if ($DryRun) {
  Write-Host "  (DryRun: git 푸시는 건너뜀)" -ForegroundColor Yellow
  exit 0
}

# 4) git 커밋 & 푸시
Set-Location $here
Write-Host "  업로드 중..." -ForegroundColor Green
git pull --rebase --quiet
git add index.html
git commit -q -m "Update video list ($($data.Count) videos)"
git push --quiet

Write-Host ""
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host "   완료! 1~2분 뒤 사이트에 반영돼요." -ForegroundColor Green
Write-Host "   https://m3ro33.github.io/mero-mv/"
Write-Host "  ===============================================" -ForegroundColor Green
Write-Host ""
