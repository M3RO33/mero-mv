param([switch]$SelfTest)

Add-Type -AssemblyName PresentationFramework

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $scriptDir 'index.html'

$cheers = @('오늘도 최고예요 🍒', '멋진 작업이에요 ✨', '반짝반짝 ⭐', '수고했어요 🍈', '역시 MERO! 💚', '완벽해요 🎬')

# ---------- 핵심 로직 ----------
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

# ---------- 화면(XAML) ----------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MERO STUDIO" Height="700" Width="480"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        FontFamily="Malgun Gothic" AllowsTransparency="False">
  <Window.Background>
    <LinearGradientBrush StartPoint="0,0" EndPoint="0.4,1">
      <GradientStop Color="#FFFDF6" Offset="0"/>
      <GradientStop Color="#EAF7D6" Offset="0.55"/>
      <GradientStop Color="#FDE8EE" Offset="1"/>
    </LinearGradientBrush>
  </Window.Background>

  <Window.Resources>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="17"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Height" Value="56"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="28" BorderBrush="#3F7212" BorderThickness="3"
                    RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform x:Name="sc" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#A8E063" Offset="0"/>
                  <GradientStop Color="#56AB2F" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <Border.Effect><DropShadowEffect Color="#5A9622" BlurRadius="18" ShadowDepth="0" Opacity="0.6"/></Border.Effect>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <EventTrigger RoutedEvent="MouseEnter">
                <BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleX" To="1.05" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleY" To="1.05" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard>
              </EventTrigger>
              <EventTrigger RoutedEvent="MouseLeave">
                <BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard>
              </EventTrigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid>
    <Canvas x:Name="FxCanvas" IsHitTestVisible="False" Panel.ZIndex="5"/>

    <!-- 떠다니는 반짝이 -->
    <TextBlock Text="&#10022;" FontSize="18" Foreground="#BCE98A" Canvas.Left="0" Margin="40,120,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5">
      <TextBlock.RenderTransform><TranslateTransform/></TextBlock.RenderTransform>
      <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
        <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)" From="0" To="-20" Duration="0:0:2.2" AutoReverse="True" RepeatBehavior="Forever"/>
        <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.35" To="1" Duration="0:0:1.4" AutoReverse="True" RepeatBehavior="Forever"/>
      </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
    </TextBlock>
    <TextBlock Text="&#9733;" FontSize="14" Foreground="#F6B8C8" Margin="0,90,52,0" HorizontalAlignment="Right" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5">
      <TextBlock.RenderTransform><TranslateTransform/></TextBlock.RenderTransform>
      <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
        <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)" From="0" To="16" Duration="0:0:1.8" AutoReverse="True" RepeatBehavior="Forever"/>
        <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.4" To="1" Duration="0:0:1.1" AutoReverse="True" RepeatBehavior="Forever"/>
      </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
    </TextBlock>
    <TextBlock Text="&#10022;" FontSize="13" Foreground="#8FD14F" Margin="70,0,0,120" HorizontalAlignment="Left" VerticalAlignment="Bottom" RenderTransformOrigin="0.5,0.5">
      <TextBlock.RenderTransform><TranslateTransform/></TextBlock.RenderTransform>
      <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
        <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)" From="0" To="-14" Duration="0:0:2.6" AutoReverse="True" RepeatBehavior="Forever"/>
        <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.3" To="0.9" Duration="0:0:1.6" AutoReverse="True" RepeatBehavior="Forever"/>
      </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
    </TextBlock>

    <Grid Margin="26" Panel.ZIndex="10">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <!-- 헤더: 흔들리는 메론 + 타이틀 -->
      <StackPanel Grid.Row="0" HorizontalAlignment="Center" Margin="0,6,0,4">
        <TextBlock Text="&#127816;" FontSize="40" FontFamily="Segoe UI Emoji" HorizontalAlignment="Center" RenderTransformOrigin="0.5,0.5">
          <TextBlock.RenderTransform><RotateTransform/></TextBlock.RenderTransform>
          <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(RotateTransform.Angle)" From="-13" To="13" Duration="0:0:1.5" AutoReverse="True" RepeatBehavior="Forever"/>
            <DoubleAnimation Storyboard.TargetProperty="FontSize" From="36" To="44" Duration="0:0:1.2" AutoReverse="True" RepeatBehavior="Forever"/>
          </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
        </TextBlock>
        <TextBlock FontSize="27" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,2,0,0">
          <TextBlock.Foreground>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
              <GradientStop Color="#8FD14F" Offset="0"/>
              <GradientStop Color="#56AB2F" Offset="0.5"/>
              <GradientStop Color="#D63D3D" Offset="1"/>
            </LinearGradientBrush>
          </TextBlock.Foreground>
          MERO STUDIO
        </TextBlock>
        <TextBlock Text="포폴 업데이트 콘솔  v2.0" FontSize="12" Foreground="#5A9622" HorizontalAlignment="Center" Margin="0,1,0,0"/>
      </StackPanel>

      <!-- 있어보이는 상태칩 -->
      <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,10">
        <Border Background="#E6F7CF" CornerRadius="10" Padding="10,5" Margin="4,0">
          <StackPanel Orientation="Horizontal">
            <Ellipse Width="9" Height="9" Fill="#4CAF50" VerticalAlignment="Center" Margin="0,0,6,0">
              <Ellipse.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetProperty="Opacity" From="1" To="0.25" Duration="0:0:0.9" AutoReverse="True" RepeatBehavior="Forever"/>
              </Storyboard></BeginStoryboard></EventTrigger></Ellipse.Triggers>
            </Ellipse>
            <TextBlock Text="ONLINE" FontSize="11" FontWeight="Bold" Foreground="#3F7212" VerticalAlignment="Center"/>
          </StackPanel>
        </Border>
        <Border Background="#FDE8EE" CornerRadius="10" Padding="10,5" Margin="4,0">
          <TextBlock x:Name="LblClock" Text="00:00:00" FontSize="11" FontWeight="Bold" Foreground="#B03A52"/>
        </Border>
        <Border Background="#E6F7CF" CornerRadius="10" Padding="10,5" Margin="4,0">
          <TextBlock x:Name="LblCount" Text="READY" FontSize="11" FontWeight="Bold" Foreground="#3F7212"/>
        </Border>
      </StackPanel>

      <!-- 안내 -->
      <Border Grid.Row="2" Background="#E6F7CF" CornerRadius="14" Padding="16,12" Margin="0,0,0,12">
        <Border.Effect><DropShadowEffect Color="#BCE98A" BlurRadius="14" ShadowDepth="0" Opacity="0.7"/></Border.Effect>
        <StackPanel>
          <TextBlock Text="&#9312;  사이트 편집 모드에서 '목록 내보내기' 클릭" Foreground="#3F7212" FontSize="13"/>
          <TextBlock Text="&#9313;  아래 반짝이는 버튼 클릭!" Foreground="#3F7212" FontSize="13" Margin="0,5,0,0"/>
        </StackPanel>
      </Border>

      <!-- 목록 -->
      <Border Grid.Row="3" Background="#FFFFFF" BorderBrush="#BCE98A" BorderThickness="3" CornerRadius="16" Padding="6" Margin="0,0,0,12">
        <Border.Effect><DropShadowEffect Color="#8FD14F" BlurRadius="16" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
        <ListBox x:Name="LstVideos" BorderThickness="0" Background="Transparent"
                 FontSize="12.5" Foreground="#3A4A2A" ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
      </Border>

      <!-- 진행바 -->
      <ProgressBar Grid.Row="4" x:Name="Bar" Height="10" IsIndeterminate="True" Visibility="Collapsed"
                   Foreground="#56AB2F" Background="#E6F7CF" BorderThickness="0" Margin="0,0,0,10"/>

      <!-- 버튼 -->
      <Button Grid.Row="5" x:Name="BtnUpdate" Style="{StaticResource Pill}" Content="&#128203;  불러와서 업데이트  &#10022;"/>

      <!-- 상태 + 푸터 -->
      <StackPanel Grid.Row="6" Margin="0,12,0,0">
        <TextBlock x:Name="LblStatus" Text="목록을 복사한 뒤 버튼을 눌러주세요 🍈"
                   FontSize="13" Foreground="#5A9622" HorizontalAlignment="Center"
                   TextAlignment="Center" TextWrapping="Wrap"/>
        <TextBlock Text="🍒 made with love by MERO" FontSize="11" Foreground="#C58AA0"
                   HorizontalAlignment="Center" Margin="0,8,0,0">
          <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
            <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.5" To="1" Duration="0:0:1.5" AutoReverse="True" RepeatBehavior="Forever"/>
          </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
        </TextBlock>
      </StackPanel>
    </Grid>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$BtnUpdate = $window.FindName('BtnUpdate')
$LstVideos = $window.FindName('LstVideos')
$LblStatus = $window.FindName('LblStatus')
$LblClock = $window.FindName('LblClock')
$LblCount = $window.FindName('LblCount')
$Bar = $window.FindName('Bar')
$FxCanvas = $window.FindName('FxCanvas')

function Set-Status($text, $hex) {
  $LblStatus.Text = $text
  $LblStatus.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($hex))
  $null = $LblStatus.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)
}

function Start-Confetti {
  $emojis = "🍈", "🍒", "✦", "⭐", "💚", "✨"
  $rand = New-Object System.Random
  for ($i = 0; $i -lt 46; $i++) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $emojis[$rand.Next($emojis.Count)]
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI Emoji")
    $tb.FontSize = 16 + $rand.Next(24)
    [System.Windows.Controls.Canvas]::SetLeft($tb, $rand.Next(450))
    [System.Windows.Controls.Canvas]::SetTop($tb, -40)
    $rot = New-Object System.Windows.Media.RotateTransform
    $tb.RenderTransform = $rot
    [void]$FxCanvas.Children.Add($tb)
    $dur = [TimeSpan]::FromMilliseconds(1900 + $rand.Next(1800))
    $begin = [TimeSpan]::FromMilliseconds($rand.Next(1000))
    $fall = New-Object System.Windows.Media.Animation.DoubleAnimation(-40, 760, $dur)
    $fall.BeginTime = $begin
    $spin = New-Object System.Windows.Media.Animation.DoubleAnimation(0, (360 * ($rand.Next(3) + 1)), $dur)
    $spin.BeginTime = $begin
    $fall.Add_Completed({ $FxCanvas.Children.Remove($tb) }.GetNewClosure())
    $tb.BeginAnimation([System.Windows.Controls.Canvas]::TopProperty, $fall)
    $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $spin)
  }
}

$BtnUpdate.Add_Click({
    $BtnUpdate.IsEnabled = $false
    $LstVideos.Items.Clear()
    $Bar.Visibility = 'Collapsed'
    try {
      Set-Status "불러오는 중... ✨" "#5A9622"
      $data = Read-VideosFromClipboard
      $num = 1
      foreach ($v in $data) { [void]$LstVideos.Items.Add(("{0,2}.  {1}" -f $num, $v.title)); $num++ }
      $LblCount.Text = ("{0} VIDEOS" -f $data.Count)
      Set-Status "index.html 반영 중... 📝" "#5A9622"
      Write-Seed $data
      $script:count = $data.Count
      Set-Status "업로드 중... 잠시만요 🚀" "#5A9622"
      $Bar.Visibility = 'Visible'

      $script:ps = [PowerShell]::Create()
      [void]$script:ps.AddScript({
          param($dir, $count)
          Set-Location $dir
          & git add index.html 2>&1 | Out-Null
          & git commit -q -m "Update video list ($count videos)" 2>&1 | Out-Null
          & git pull --rebase --quiet 2>&1 | Out-Null
          $out = & git push --quiet 2>&1
          if ($LASTEXITCODE -ne 0) { return ("FAIL:" + ($out -join ' ')) }
          return "OK"
        }).AddParameter('dir', $scriptDir).AddParameter('count', $script:count)
      $script:handle = $script:ps.BeginInvoke()

      $script:timer = New-Object System.Windows.Threading.DispatcherTimer
      $script:timer.Interval = [TimeSpan]::FromMilliseconds(200)
      $script:timer.Add_Tick({
          if (-not $script:handle.IsCompleted) { return }
          $script:timer.Stop()
          $res = "$($script:ps.EndInvoke($script:handle))"
          $script:ps.Dispose()
          $Bar.Visibility = 'Collapsed'
          if ($res -like 'OK*') {
            $cheer = $cheers[(New-Object System.Random).Next($cheers.Count)]
            Set-Status ("✓ 완료! 영상 {0}개 · {1}`n1~2분 뒤 사이트에 반영돼요" -f $script:count, $cheer) "#3F7212"
            Start-Confetti
            try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
          }
          else {
            Set-Status ("⚠ " + ($res -replace '^FAIL:', '')) "#D63D3D"
          }
          $BtnUpdate.IsEnabled = $true
        })
      $script:timer.Start()
    }
    catch {
      $Bar.Visibility = 'Collapsed'
      Set-Status ("⚠ " + $_.Exception.Message) "#D63D3D"
      $BtnUpdate.IsEnabled = $true
    }
  })

if ($SelfTest) { Write-Output "SELFTEST_OK"; return }

$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({ $LblClock.Text = (Get-Date).ToString('HH:mm:ss') })
$clockTimer.Start()
$LblClock.Text = (Get-Date).ToString('HH:mm:ss')

[void]$window.ShowDialog()
