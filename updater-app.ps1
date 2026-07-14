param([switch]$SelfTest)

Add-Type -AssemblyName PresentationFramework

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $scriptDir 'index.html'

$cheers = @('오늘도 최고예요 🍒', '멋진 작업이에요 ✨', '반짝반짝 ⭐', '수고했어요 🍈', '역시 MERO! 💚', '완벽해요 🎬')
$taglines = @('✨ 반짝이는 포트폴리오 ✨', '🍈 메론빵 스튜디오 🍈', '🎬 이야기를 담는 영상 🎬', '💚 MERO STUDIO 💚', '⭐ 오늘도 반짝반짝 ⭐')

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
function Build-SeedBlock($data) {
  $lines = foreach ($v in $data) {
    $t = ([string]$v.title) -replace '\\', '\\' -replace '"', '\"'
    '  { "id": "' + $v.id + '", "title": "' + $t + '" }'
  }
  "const SEED_VIDEOS = [`n" + ($lines -join ",`n") + "`n];"
}

# ---------- 화면(XAML) ----------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MERO STUDIO" Width="480" Height="726"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        FontFamily="Malgun Gothic">
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
            <Border x:Name="bd" CornerRadius="28" BorderBrush="White" BorderThickness="2.5" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform x:Name="sc" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#FF8AD4" Offset="0"/>
                  <GradientStop Color="#A8E063" Offset="0.5"/>
                  <GradientStop Color="#56AB2F" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <Border.Effect><DropShadowEffect Color="#8FD14F" BlurRadius="26" ShadowDepth="0" Opacity="0.85"/></Border.Effect>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleX" To="1.06" Duration="0:0:0.15"/>
                <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleY" To="1.06" Duration="0:0:0.15"/>
              </Storyboard></BeginStoryboard></EventTrigger>
              <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.15"/>
                <DoubleAnimation Storyboard.TargetName="sc" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.15"/>
              </Storyboard></BeginStoryboard></EventTrigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="MiniPill" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Height" Value="44"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="mb" CornerRadius="22" Background="{TemplateBinding Background}" BorderBrush="White" BorderThickness="2" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform x:Name="ms" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <Border.Effect><DropShadowEffect Color="#66000000" BlurRadius="12" ShadowDepth="0" Opacity="0.4"/></Border.Effect>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="ms" Storyboard.TargetProperty="ScaleX" To="1.05" Duration="0:0:0.12"/>
                <DoubleAnimation Storyboard.TargetName="ms" Storyboard.TargetProperty="ScaleY" To="1.05" Duration="0:0:0.12"/>
              </Storyboard></BeginStoryboard></EventTrigger>
              <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="ms" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.12"/>
                <DoubleAnimation Storyboard.TargetName="ms" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.12"/>
              </Storyboard></BeginStoryboard></EventTrigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="Root" Margin="18" CornerRadius="30" BorderBrush="#FFFFFF" BorderThickness="2">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop x:Name="bgStop1" Color="#FFF6E9" Offset="0"/>
        <GradientStop x:Name="bgStop2" Color="#E7F7CE" Offset="0.5"/>
        <GradientStop x:Name="bgStop3" Color="#FDE3EE" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Border.Effect><DropShadowEffect x:Name="glow" Color="#8FD14F" BlurRadius="30" ShadowDepth="0" Opacity="0.8"/></Border.Effect>

    <Grid>
      <!-- 회전 후광 -->
      <TextBlock Text="&#10022;" FontSize="230" Foreground="#33BCE98A" HorizontalAlignment="Center" VerticalAlignment="Top"
                 Margin="0,-40,0,0" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
        <TextBlock.RenderTransform><RotateTransform x:Name="haloRot"/></TextBlock.RenderTransform>
      </TextBlock>

      <Canvas x:Name="FxCanvas" Panel.ZIndex="20" ClipToBounds="True"/>

      <Grid Margin="24,14,24,22" Panel.ZIndex="10">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- 드래그바 + 창 컨트롤 -->
        <Grid x:Name="DragBar" Grid.Row="0" Background="Transparent" Height="26">
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Border x:Name="BtnMin" Width="24" Height="24" CornerRadius="12" Background="#33FFFFFF" Margin="0,0,6,0" Cursor="Hand">
              <TextBlock Text="&#8211;" FontSize="15" FontWeight="Bold" Foreground="#3F7212" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <Border x:Name="BtnClose" Width="24" Height="24" CornerRadius="12" Background="#33D63D3D" Cursor="Hand">
              <TextBlock Text="&#10005;" FontSize="12" FontWeight="Bold" Foreground="#A82828" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
          </StackPanel>
        </Grid>

        <!-- 헤더 -->
        <StackPanel Grid.Row="1" HorizontalAlignment="Center" Margin="0,2,0,4">
          <TextBlock Text="&#127816;" FontSize="42" FontFamily="Segoe UI Emoji" HorizontalAlignment="Center" RenderTransformOrigin="0.5,0.5">
            <TextBlock.RenderTransform><RotateTransform/></TextBlock.RenderTransform>
            <TextBlock.Effect><DropShadowEffect Color="#8FD14F" BlurRadius="20" ShadowDepth="0" Opacity="0.9"/></TextBlock.Effect>
            <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
              <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(RotateTransform.Angle)" From="-14" To="14" Duration="0:0:1.4" AutoReverse="True" RepeatBehavior="Forever"/>
              <DoubleAnimation Storyboard.TargetProperty="FontSize" From="38" To="47" Duration="0:0:1.1" AutoReverse="True" RepeatBehavior="Forever"/>
            </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
          </TextBlock>
          <TextBlock FontSize="29" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,2,0,0">
            <TextBlock.Effect><DropShadowEffect Color="#FFB3D9" BlurRadius="14" ShadowDepth="0" Opacity="0.6"/></TextBlock.Effect>
            <TextBlock.Foreground>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                <GradientStop x:Name="tStop1" Color="#8FD14F" Offset="0"/>
                <GradientStop x:Name="tStop2" Color="#FF6EC7" Offset="0.5"/>
                <GradientStop x:Name="tStop3" Color="#56AB2F" Offset="1"/>
              </LinearGradientBrush>
            </TextBlock.Foreground>
            MERO STUDIO
          </TextBlock>
          <TextBlock x:Name="LblTagline" Text="✨ 반짝이는 포트폴리오 ✨" FontSize="12.5" Foreground="#7A9C3E" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>

        <!-- 상태칩 -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,8,0,10">
          <Border Background="#CCE6F7CF" CornerRadius="10" Padding="10,5" Margin="4,0">
            <StackPanel Orientation="Horizontal">
              <Ellipse Width="9" Height="9" Fill="#4CAF50" VerticalAlignment="Center" Margin="0,0,6,0">
                <Ellipse.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetProperty="Opacity" From="1" To="0.2" Duration="0:0:0.8" AutoReverse="True" RepeatBehavior="Forever"/>
                </Storyboard></BeginStoryboard></EventTrigger></Ellipse.Triggers>
              </Ellipse>
              <TextBlock Text="ONLINE" FontSize="11" FontWeight="Bold" Foreground="#3F7212" VerticalAlignment="Center"/>
            </StackPanel>
          </Border>
          <Border Background="#CCFDE8EE" CornerRadius="10" Padding="10,5" Margin="4,0">
            <TextBlock x:Name="LblClock" Text="00:00:00" FontSize="11" FontWeight="Bold" Foreground="#B03A52"/>
          </Border>
          <Border Background="#CCE6F7CF" CornerRadius="10" Padding="10,5" Margin="4,0">
            <TextBlock x:Name="LblCount" Text="READY" FontSize="11" FontWeight="Bold" Foreground="#3F7212"/>
          </Border>
          <Border Background="#CCFDE8EE" CornerRadius="10" Padding="10,5" Margin="4,0" Cursor="Hand" ToolTip="떨어지는 반짝이를 클릭해 터뜨려 보세요!">
            <TextBlock x:Name="LblScore" Text="✨ 0" FontSize="11" FontWeight="Bold" Foreground="#B06AB3"/>
          </Border>
        </StackPanel>

        <!-- 안내 -->
        <Border Grid.Row="3" Background="#CCE6F7CF" CornerRadius="14" Padding="16,12" Margin="0,0,0,12">
          <Border.Effect><DropShadowEffect Color="#BCE98A" BlurRadius="14" ShadowDepth="0" Opacity="0.7"/></Border.Effect>
          <StackPanel>
            <TextBlock Text="&#9312;  사이트 편집 모드에서 '목록 내보내기' 클릭" Foreground="#3F7212" FontSize="13"/>
            <TextBlock Text="&#9313;  아래 반짝이는 버튼 클릭!" Foreground="#3F7212" FontSize="13" Margin="0,5,0,0"/>
          </StackPanel>
        </Border>

        <!-- 목록 -->
        <Border Grid.Row="4" Background="#F2FFFFFF" BorderThickness="3" CornerRadius="16" Padding="6" Margin="0,0,0,12">
          <Border.BorderBrush><SolidColorBrush x:Name="cardBrush" Color="#BCE98A"/></Border.BorderBrush>
          <Border.Effect><DropShadowEffect Color="#8FD14F" BlurRadius="16" ShadowDepth="0" Opacity="0.4"/></Border.Effect>
          <ListBox x:Name="LstVideos" BorderThickness="0" Background="Transparent" FontSize="12.5" Foreground="#3A4A2A" ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
        </Border>

        <!-- 진행바 -->
        <ProgressBar Grid.Row="5" x:Name="Bar" Height="10" IsIndeterminate="True" Visibility="Collapsed" Foreground="#56AB2F" Background="#E6F7CF" BorderThickness="0" Margin="0,0,0,10"/>

        <!-- 버튼 -->
        <Button Grid.Row="6" x:Name="BtnUpdate" Style="{StaticResource Pill}" Content="&#128203;  불러와서 업데이트  &#10022;"/>

        <!-- 보조 버튼: 사이트 열기 / 오늘의 운세 -->
        <Grid Grid.Row="7" Margin="0,10,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="10"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <Button x:Name="BtnSite" Grid.Column="0" Style="{StaticResource MiniPill}" Content="🌐 사이트 열기">
            <Button.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#7AC7FF" Offset="0"/><GradientStop Color="#4A90E2" Offset="1"/>
              </LinearGradientBrush>
            </Button.Background>
          </Button>
          <Button x:Name="BtnLuck" Grid.Column="2" Style="{StaticResource MiniPill}" Content="🔮 오늘의 운세">
            <Button.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#FF9FD6" Offset="0"/><GradientStop Color="#B06AB3" Offset="1"/>
              </LinearGradientBrush>
            </Button.Background>
          </Button>
        </Grid>

        <!-- 상태 + 푸터 -->
        <StackPanel Grid.Row="8" Margin="0,12,0,0">
          <TextBlock x:Name="LblStatus" Text="목록을 복사한 뒤 버튼을 눌러주세요 🍈" FontSize="13" Foreground="#5A9622" HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap"/>
          <TextBlock Text="🍒 made with love by MERO" FontSize="11" Foreground="#C58AA0" HorizontalAlignment="Center" Margin="0,8,0,0">
            <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
              <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.45" To="1" Duration="0:0:1.5" AutoReverse="True" RepeatBehavior="Forever"/>
            </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
          </TextBlock>
        </StackPanel>
      </Grid>
    </Grid>
  </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
foreach ($n in 'Root', 'glow', 'bgStop1', 'bgStop2', 'bgStop3', 'tStop1', 'tStop2', 'tStop3', 'haloRot', 'cardBrush', 'FxCanvas', 'DragBar', 'BtnMin', 'BtnClose', 'BtnUpdate', 'BtnSite', 'BtnLuck', 'LstVideos', 'LblStatus', 'LblClock', 'LblCount', 'LblScore', 'LblTagline', 'Bar') {
  Set-Variable -Name $n -Value $window.FindName($n)
}
$script:score = 0
$fortunes = @(
  '🍀 뜻밖의 행운이 찾아오는 날이에요',
  '🌈 오래 기다린 소식이 곧 도착해요',
  '💰 작은 지출은 나중에 큰 이득으로 돌아와요',
  '🤝 오늘 만나는 사람 중에 귀인이 있어요',
  '📈 노력한 만큼 결과가 따라오는 하루',
  '🌟 자신감을 가지면 일이 술술 풀려요',
  '🕊️ 마음의 여유가 행운을 부릅니다',
  '🎁 예상치 못한 선물이 기다리고 있어요',
  '☀️ 흐렸던 일이 맑게 개는 날이에요',
  '🧭 망설이던 결정에 좋은 답이 나와요',
  '💌 반가운 연락이 올 거예요',
  '🌱 새로 시작하기 딱 좋은 날이에요',
  '🔑 닫혀 있던 기회의 문이 열려요',
  '🍯 달콤한 보상이 기다리는 하루',
  '🪄 작은 기적이 일어날지도 몰라요',
  '🎯 목표에 한 걸음 더 가까워져요',
  '🌸 인간관계에서 좋은 일이 생겨요',
  '⚖️ 미뤄둔 일을 정리하기 좋은 날이에요',
  '🛡️ 어려움이 와도 잘 이겨낼 거예요',
  '🎂 가까운 날에 축하할 일이 생겨요',
  '🔮 직감을 믿으면 좋은 선택을 하게 돼요',
  '🌊 흐름을 타면 순조롭게 풀리는 하루',
  '🧩 고민하던 문제의 실마리가 보여요',
  '💎 당신의 진가를 알아봐 주는 사람이 있어요',
  '🌻 긍정적인 마음이 좋은 기운을 불러와요',
  '🎈 오늘은 작은 일에도 기분 좋은 날',
  '🌙 무리하지 말고 오늘은 푹 쉬어요',
  '💧 물 한 잔의 여유를 잊지 마세요',
  '🧘 조급함을 내려놓으면 길이 보여요',
  '🍵 잠깐의 휴식이 큰 힘이 돼요',
  '🚶 가벼운 산책이 영감을 줄 거예요',
  '📵 가끔은 화면에서 눈을 떼어 쉬어주세요',
  '🎬 컷 편집이 술술 풀리는 날이에요',
  '🍈 메론빵이 행운을 가져다줄 거예요',
  '✨ 좋은 레퍼런스를 발견할 예감이에요',
  '🎧 인생 노래를 만나는 날이에요',
  '🖥️ 오늘은 렌더링이 한 번에 될 거예요',
  '💚 구독자가 늘어날 조짐이 보여요!',
  '🔥 오늘의 작업물은 역대급이 될 거예요',
  '🎨 색감이 유난히 잘 뽑히는 하루',
  '💾 저장은 자주! 오늘은 특히 조심하세요',
  '🏆 당신의 영상이 누군가의 하루를 밝혀요',
  '⏳ 마감이 생각보다 여유로울 거예요',
  '🌟 오래 준비한 작업이 빛을 볼 때예요'
)

# ---------- 애니메이션 헬퍼 ----------
function Col($hex) { [System.Windows.Media.Color]([System.Windows.Media.ColorConverter]::ConvertFromString($hex)) }
function Cycle-Color($obj, $dp, $hexes, $secs) {
  $anim = New-Object System.Windows.Media.Animation.ColorAnimationUsingKeyFrames
  $anim.Duration = [TimeSpan]::FromSeconds($secs)
  $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
  $n = $hexes.Count
  for ($i = 0; $i -lt $n; $i++) {
    $kt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($secs * $i / ($n - 1)))
    [void]$anim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearColorKeyFrame ((Col $hexes[$i]), $kt)))
  }
  $obj.BeginAnimation($dp, $anim)
}
function Pulse-Double($obj, $dp, $from, $to, $secs) {
  $a = New-Object System.Windows.Media.Animation.DoubleAnimation ($from, $to, [TimeSpan]::FromSeconds($secs))
  $a.AutoReverse = $true; $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
  $obj.BeginAnimation($dp, $a)
}
function Set-Status($text, $hex) {
  $LblStatus.Text = $text
  $LblStatus.Foreground = New-Object System.Windows.Media.SolidColorBrush (Col $hex)
  $null = $LblStatus.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)
}

$emojis = "🍈", "🍒", "✦", "⭐", "💚", "✨", "🌟", "🍬"
$rand = New-Object System.Random
function Spawn-Particle($big) {
  $tb = New-Object System.Windows.Controls.TextBlock
  $tb.Text = $emojis[$rand.Next($emojis.Count)]
  $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI Emoji")
  $tb.FontSize = $(if ($big) { 16 + $rand.Next(24) } else { 11 + $rand.Next(12) })
  $tb.Opacity = $(if ($big) { 1 } else { 0.7 })
  [System.Windows.Controls.Canvas]::SetLeft($tb, $rand.Next(430))
  [System.Windows.Controls.Canvas]::SetTop($tb, -40)
  $rot = New-Object System.Windows.Media.RotateTransform
  $tb.RenderTransform = $rot
  [void]$FxCanvas.Children.Add($tb)
  $tb.Cursor = [System.Windows.Input.Cursors]::Hand
  $tb.Add_MouseLeftButtonDown({
      $script:score++
      $LblScore.Text = "✨ $($script:score)"
      $FxCanvas.Children.Remove($args[0])
      $args[1].Handled = $true
      try { [System.Media.SystemSounds]::Hand.Play() } catch {}
    })
  $dur = [TimeSpan]::FromMilliseconds($(if ($big) { 1900 + $rand.Next(1700) } else { 3500 + $rand.Next(2500) }))
  $begin = [TimeSpan]::FromMilliseconds($(if ($big) { $rand.Next(1000) } else { 0 }))
  $fall = New-Object System.Windows.Media.Animation.DoubleAnimation (-40, 720, $dur); $fall.BeginTime = $begin
  $spin = New-Object System.Windows.Media.Animation.DoubleAnimation (0, (360 * ($rand.Next(3) + 1)), $dur); $spin.BeginTime = $begin
  $fall.Add_Completed({ $FxCanvas.Children.Remove($tb) }.GetNewClosure())
  $tb.BeginAnimation([System.Windows.Controls.Canvas]::TopProperty, $fall)
  $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $spin)
}
function Start-Confetti { for ($i = 0; $i -lt 50; $i++) { Spawn-Particle $true } }

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
      Set-Status "목록 준비 중... 📝" "#5A9622"
      $block = Build-SeedBlock $data
      $script:count = $data.Count
      Set-Status "업로드 중... 잠시만요 🚀" "#5A9622"
      $Bar.Visibility = 'Visible'
      $script:ps = [PowerShell]::Create()
      [void]$script:ps.AddScript({
          param($dir, $count, $block)
          Set-Location $dir
          # 갓 clone한 저장소엔 git 신원이 없어서 commit이 조용히 실패함 → 없으면 자동 설정
          if (-not (git config user.email)) {
            git config user.email "m3ro3333@gmail.com"
            git config user.name  "MERO"
          }
          # 항상 최신 원본을 기준으로 목록을 다시 얹어 올림 (뒤처짐/충돌 방지)
          git fetch origin 2>&1 | Out-Null
          if ($LASTEXITCODE -ne 0) { return "FAIL: 인터넷 연결 또는 GitHub 접속에 실패했어요 (git fetch)" }
          git reset --hard origin/main 2>&1 | Out-Null
          $idx = Join-Path $dir 'index.html'
          $content = [System.IO.File]::ReadAllText($idx)
          $s = $content.IndexOf('const SEED_VIDEOS = [')
          $e = if ($s -ge 0) { $content.IndexOf('];', $s) } else { -1 }
          if ($s -lt 0 -or $e -lt 0) { return "FAIL: index.html에서 목록 위치를 못 찾았어요" }
          $newContent = $content.Substring(0, $s) + $block + $content.Substring($e + 2)
          [System.IO.File]::WriteAllText($idx, $newContent, (New-Object System.Text.UTF8Encoding($false)))
          git add index.html 2>&1 | Out-Null
          if ([string]::IsNullOrWhiteSpace((git status --porcelain))) { return "OK" }
          git commit -q -m "Update video list ($count videos)" 2>&1 | Out-Null
          $out = git push 2>&1
          if ($LASTEXITCODE -ne 0) { return ("FAIL:" + (($out | Out-String).Trim())) }
          return "OK"
        }).AddParameter('dir', $scriptDir).AddParameter('count', $script:count).AddParameter('block', $block)
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
            $cheer = $cheers[$rand.Next($cheers.Count)]
            Set-Status ("✓ 완료! 영상 {0}개 · {1}`n1~2분 뒤 사이트에 반영돼요" -f $script:count, $cheer) "#3F7212"
            Start-Confetti
            try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
          } else {
            Set-Status ("⚠ " + ($res -replace '^FAIL:', '')) "#D63D3D"
          }
          $BtnUpdate.IsEnabled = $true
        })
      $script:timer.Start()
    } catch {
      $Bar.Visibility = 'Collapsed'
      Set-Status ("⚠ " + $_.Exception.Message) "#D63D3D"
      $BtnUpdate.IsEnabled = $true
    }
  })

# 창 컨트롤
$DragBar.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
$BtnClose.Add_MouseLeftButtonDown({ $args[1].Handled = $true; $window.Close() })
$BtnMin.Add_MouseLeftButtonDown({ $args[1].Handled = $true; $window.WindowState = 'Minimized' })

# 사이트 열기 / 오늘의 운세
$BtnSite.Add_Click({ Start-Process 'https://m3ro33.github.io/mero-mv/' })
$BtnLuck.Add_Click({
    $f = $fortunes[$rand.Next($fortunes.Count)]
    Set-Status $f "#8E44AD"
    for ($i = 0; $i -lt 16; $i++) { Spawn-Particle $true }
    try { [System.Media.SystemSounds]::Exclamation.Play() } catch {}
  })

if ($SelfTest) { Write-Output "SELFTEST_OK"; return }

# ---------- 미친듯한 상시 애니메이션 시작 ----------
Cycle-Color $bgStop1 ([System.Windows.Media.GradientStop]::ColorProperty) @('#FFF6E9', '#E7F7CE', '#FDE3EE', '#E9F0FF', '#FFF6E9') 14
Cycle-Color $bgStop2 ([System.Windows.Media.GradientStop]::ColorProperty) @('#E7F7CE', '#FDE3EE', '#E9F0FF', '#FFF6E9', '#E7F7CE') 14
Cycle-Color $bgStop3 ([System.Windows.Media.GradientStop]::ColorProperty) @('#FDE3EE', '#E9F0FF', '#FFF6E9', '#E7F7CE', '#FDE3EE') 14
Cycle-Color $glow ([System.Windows.Media.Effects.DropShadowEffect]::ColorProperty) @('#8FD14F', '#FF8AD4', '#7AC7FF', '#FFD86E', '#8FD14F') 10
Pulse-Double $glow ([System.Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty) 24 42 2.2
Cycle-Color $cardBrush ([System.Windows.Media.SolidColorBrush]::ColorProperty) @('#BCE98A', '#FFB3D9', '#9FD8FF', '#FFE08A', '#BCE98A') 8
Cycle-Color $tStop2 ([System.Windows.Media.GradientStop]::ColorProperty) @('#FF6EC7', '#FFD86E', '#7AC7FF', '#FF6EC7') 6

# 후광 회전
$haloAnim = New-Object System.Windows.Media.Animation.DoubleAnimation (0, 360, [TimeSpan]::FromSeconds(22))
$haloAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
$haloRot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $haloAnim)

# 상시 반짝이 낙하
$fxTimer = New-Object System.Windows.Threading.DispatcherTimer
$fxTimer.Interval = [TimeSpan]::FromMilliseconds(420)
$fxTimer.Add_Tick({ Spawn-Particle $false })
$fxTimer.Start()

# 실시간 시계
$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({ $LblClock.Text = (Get-Date).ToString('HH:mm:ss') })
$clockTimer.Start()
$LblClock.Text = (Get-Date).ToString('HH:mm:ss')

# 문구 교체
$script:tagi = 0
$tagTimer = New-Object System.Windows.Threading.DispatcherTimer
$tagTimer.Interval = [TimeSpan]::FromSeconds(3)
$tagTimer.Add_Tick({
    $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation (1, 0, [TimeSpan]::FromSeconds(0.4))
    $fadeOut.Add_Completed({
        $script:tagi = ($script:tagi + 1) % $taglines.Count
        $LblTagline.Text = $taglines[$script:tagi]
        $fin = New-Object System.Windows.Media.Animation.DoubleAnimation (0, 1, [TimeSpan]::FromSeconds(0.4))
        $LblTagline.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fin)
      })
    $LblTagline.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeOut)
  })
$tagTimer.Start()

[void]$window.ShowDialog()
