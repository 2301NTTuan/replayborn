param([string]$Godot = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($Godot)) {
    $Godot = (Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
}
if ([string]::IsNullOrWhiteSpace($Godot) -or -not (Test-Path $Godot)) {
    throw 'Godot 4.7.2 was not found. Pass -Godot C:\path\to\Godot_v4.7.2-stable_win64_console.exe.'
}
$checks = @('tools/validate_resources.gd', 'tests/time_circuit_smoke.gd', 'tests/circuit_finisher_smoke.gd', 'tests/chrono_shift_smoke.gd', 'tests/prototype_smoke.gd', 'tests/session_smoke.gd', 'tests/tutorial_smoke.gd', 'tests/run_smoke.gd', 'tests/enemy_roster_smoke.gd', 'tests/effect_lifecycle_smoke.gd', 'tests/hud_layout_smoke.gd', 'tests/menu_flow_smoke.gd')
foreach ($check in $checks) {
    $output = & $Godot --headless --path $projectRoot --script "res://$check" 2>&1
    $result = $LASTEXITCODE
    $output | Write-Output
    if ($result -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|leaked at exit')) {
        throw "Validation failed: $check"
    }
}
Write-Output 'ALL CHECKS PASSED'
