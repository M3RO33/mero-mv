param([switch]$SelfTest)

Add-Type -AssemblyName PresentationFramework

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $scriptDir 'index.html'

# ---------- 핵심 로직: 클립보드 목록 -> index.html 반영 -> 배포 ----------
function Read-VideosFromClipboard {
  $clip = Get-Clipboard -Raw
  if ([string]::IsNullOrWhiteSpace($clip)) { throw "클립보드가 비어 있어요. 사이트에서 '목록 내보내기'를 먼저 눌러주세요!" }
  try { $data = $clip | ConvertFrom-Json } catch { throw "복사된 내용이 올바른 목록이 아니에요. '목록 내보내기'를 다시 눌러 복사해 주세요." }
  if ($data -isnot [System.Array]) { $data = @($data) }
  if ($data.Count -eq 0) { throw "목록이 비어 있어요." }
  foreach ($v in $data) { if (-not $v.id -or -not $v.title) { throw "목록에 id/title이 없어요. '목록 내보내기'로 복사한 내용인지 확인해 주세요." } }
  return $data
}

function Write-Seed($data) {
  $lines = foreach ($v in $data) {
    $t = ([string]$v.title) -replace '\\', '\\' -replace '"', '\"'
    '  { "id": "' + $v.id + '", "title": "' + $t + '" }'
  }
  $block = "const SEED_VIDEOS = [`n" + ($lines -join ",`n") + "`n];"
  $content = [System.IO.File]::ReadAllText($indexPath)
  $rx = [regex]'(?s)const SEED_VIDEOS = \[.*?\];'
  if (-not $rx.IsMatch($content)) { throw "index.html에서 목록 위치(SEED_VIDEOS)를 못 찾았어요." }
  $content = $rx.Replace($content, { param($m) $block }, 1)
  [System.IO.File]::WriteAllText($indexPath, $content, (New-Object System.Text.UTF8Encoding($false)))
}

function Push-Site($count) {
  Set-Location $scriptDir
  & git add index.html 2>&1 | Out-Null
  & git commit -q -m "Update video list ($count videos)" 2>&1 | Out-Null
  & git pull --rebase --quiet 2>&1 | Out-Null
  $out = & git push --quiet 2>&1
  if ($LASTEXITCODE -ne 0) { throw ("업로드(git push) 실패: " + ($out -join ' ')) }
}

# ---------- 화면(XAML) ----------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MERO 포폴 업데이트" Height="600" Width="460"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#FFFDF6" FontFamily="Malgun Gothic">
  <Window.Resources>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="16"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Height" Value="54"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="27" BorderBrush="#3F7212" BorderThickness="3">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                  <GradientStop Color="#8FD14F" Offset="0"/>
                  <GradientStop Color="#5A9622" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Opacity" Value="0.9"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,4,0,10">
      <TextBlock Text="&#127816;" FontSize="30" FontFamily="Segoe UI Emoji" Margin="0,0,8,0"/>
      <TextBlock Text="MERO 포폴 업데이트" FontSize="24" FontWeight="Bold" Foreground="#5A9622" VerticalAlignment="Center"/>
    </StackPanel>

    <Border Grid.Row="1" Background="#E6F7CF" CornerRadius="14" Padding="16,13" Margin="0,0,0,12">
      <StackPanel>
        <TextBlock Text="&#9312;  사이트 편집 모드에서 '목록 내보내기' 클릭" Foreground="#3F7212" FontSize="13"/>
        <TextBlock Text="&#9313;  아래 '불러와서 업데이트' 버튼 클릭" Foreground="#3F7212" FontSize="13" Margin="0,5,0,0"/>
      </StackPanel>
    </Border>

    <Border Grid.Row="2" Background="White" BorderBrush="#BCE98A" BorderThickness="3" CornerRadius="16" Padding="6" Margin="0,0,0,14">
      <ListBox x:Name="LstVideos" BorderThickness="0" Background="Transparent"
               FontSize="12.5" Foreground="#3A4A2A" ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
    </Border>

    <Button Grid.Row="3" x:Name="BtnUpdate" Style="{StaticResource Pill}" Content="&#128203;  불러와서 업데이트"/>

    <TextBlock Grid.Row="4" x:Name="LblStatus" Text="목록을 복사한 뒤 버튼을 눌러주세요 🍈"
               FontSize="13" Foreground="#5A9622" HorizontalAlignment="Center"
               TextAlignment="Center" TextWrapping="Wrap" Margin="0,12,0,0"/>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$BtnUpdate = $window.FindName('BtnUpdate')
$LstVideos = $window.FindName('LstVideos')
$LblStatus = $window.FindName('LblStatus')

function Set-Status($text, $hex) {
  $LblStatus.Text = $text
  $LblStatus.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($hex))
  $null = $LblStatus.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)
}

$BtnUpdate.Add_Click({
    $BtnUpdate.IsEnabled = $false
    $LstVideos.Items.Clear()
    try {
      Set-Status "불러오는 중..." "#5A9622"
      $data = Read-VideosFromClipboard
      $n = 1
      foreach ($v in $data) { [void]$LstVideos.Items.Add(("{0,2}.  {1}" -f $n, $v.title)); $n++ }
      Set-Status "index.html 반영 중..." "#5A9622"
      Write-Seed $data
      Set-Status "업로드 중... 잠시만요 🍈" "#5A9622"
      Push-Site $data.Count
      Set-Status ("✓ 완료! 영상 {0}개 · 1~2분 뒤 사이트에 반영돼요" -f $data.Count) "#3F7212"
    }
    catch {
      Set-Status ("⚠ " + $_.Exception.Message) "#D63D3D"
    }
    finally {
      $BtnUpdate.IsEnabled = $true
    }
  })

if ($SelfTest) { Write-Output "SELFTEST_OK"; return }
[void]$window.ShowDialog()
