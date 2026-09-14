param([string]$Godot = 'C:\Users\tuann\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$checks = @('tools/validate_resources.gd', 'tests/prototype_smoke.gd', 'tests/session_smoke.gd', 'tests/run_smoke.gd', 'tests/enemy_roster_smoke.gd')
foreach ($check in $checks) {
    $output = & $Godot --headless --path $projectRoot --script "res://$check" 2>&1
    $result = $LASTEXITCODE
    $output | Write-Output
    if ($result -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|leaked at exit')) {
        throw "Validation failed: $check"
    }
}
Write-Output 'ALL CHECKS PASSED'
