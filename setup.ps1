# Run this ONCE from the VS Code terminal (Windows PowerShell), inside the foodgo folder:
#   .\setup.ps1
# It creates the Android/iOS folders, installs packages, and adds internet + link-opening permissions.

Write-Host "Creating Flutter platform folders..."
flutter create --org com.foodgo --project-name foodgo --platforms=android,ios .

# The default test file references a sample app that doesn't exist here
if (Test-Path test\widget_test.dart) { Remove-Item test\widget_test.dart }

Write-Host "Installing packages..."
flutter pub get

$m = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $m) {
  $t = Get-Content $m -Raw
  if ($t -notmatch 'android.permission.INTERNET') {
    $add = '<uses-permission android:name="android.permission.INTERNET"/>' + "`n    " +
           '<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent></queries>' + "`n    " +
           '<application'
    $t = $t -replace '<application', $add
    Set-Content $m $t
    Write-Host "Android manifest updated."
  }
}

Write-Host ""
Write-Host "Done! Next: press F5 and enter your Supabase Project URL and publishable (anon) key when prompted."
