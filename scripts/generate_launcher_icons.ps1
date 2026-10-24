param([switch]$SkipGeneration)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
  if (-not $SkipGeneration) {
    dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw 'Icon generation failed.' }
  }
  # Version 0.13.1 ignores adaptive_icon_foreground_inset; apply it natively.
  $resourceRoot = Join-Path $projectRoot 'android/app/src/main/res'
  @'
<?xml version="1.0" encoding="utf-8"?>
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:drawable="@drawable/ic_launcher_foreground"
    android:inset="18%" />
'@ | Set-Content -Encoding utf8 (Join-Path $resourceRoot 'drawable/ic_launcher_padded.xml')
  @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_padded"/>
</adaptive-icon>
'@ | Set-Content -Encoding utf8 (Join-Path $resourceRoot 'mipmap-anydpi-v26/ic_launcher.xml')
} finally { Pop-Location }
