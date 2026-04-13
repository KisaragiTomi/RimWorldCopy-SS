# RimWorld Autotest Script
# 所有 TCP 操作超时 <= 5s，监控循环 Sleep <= 10s

$global:GameHost = "127.0.0.1"
$global:GamePort = 9090
$global:ProjectDir = "d:\MyProject\RimWorldCopy"

function Send-GameCmd {
    param([string]$Command, [hashtable]$Params = @{})
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect($global:GameHost, $global:GamePort)
        $stream = $tcp.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $reader = New-Object System.IO.StreamReader($stream)
        $json = @{command=$Command; params=$Params} | ConvertTo-Json -Compress
        $writer.WriteLine($json)
        $writer.Flush()
        $tcp.ReceiveTimeout = 5000
        $raw = $reader.ReadLine()
        $tcp.Close()
        return ($raw | ConvertFrom-Json)
    } catch {
        if ($tcp.Connected) { $tcp.Close() }
        return @{success=$false; error=$_.Exception.Message}
    }
}

function Send-Eval {
    param([string]$Code)
    $Code = $Code -replace "`r`n", "`n"
    $Code = $Code -replace "(?m)^    ", "`t"
    $Code = $Code -replace "(?m)^`t    ", "`t`t"
    $Code = $Code -replace "(?m)^`t`t    ", "`t`t`t"
    return Send-GameCmd -Command "eval" -Params @{code=$Code}
}

function Get-GameStatus {
    $code = @"
var tm = TickManager
var d = tm.get_date()
var dead_c = 0
var downed_c = 0
var enemy_c = 0
for p in PawnManager.pawns:
    if p.dead: dead_c += 1
    if p.downed: downed_c += 1
    if p.has_meta("faction") and p.get_meta("faction") == "enemy": enemy_c += 1
return {"tick": tm.current_tick, "year": d.year, "quadrum": d.quadrum, "day": d.day, "pawns": PawnManager.pawns.size(), "dead": dead_c, "downed": downed_c, "enemy": enemy_c, "fps": Engine.get_frames_per_second(), "things": ThingManager.things.size(), "temp": GameState.temperature}
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Get-JobDistribution {
    $code = @"
var jobs = {}
for p in PawnManager.pawns:
    var jn = p.current_job_name if p.current_job_name != "" else "Idle"
    jobs[jn] = jobs.get(jn, 0) + 1
return jobs
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Save-GameScreenshot {
    param([string]$Name = "screenshot")
    $r = Send-GameCmd -Command "screenshot"
    if (-not $r -or -not $r.success) { return "FAIL: no response" }
    $b64 = $null
    if ($r.data) { $b64 = $r.data }
    elseif ($r.result -and $r.result.image) { $b64 = $r.result.image }
    if (-not $b64) { return "FAIL: no image data" }
    $path = "$global:ProjectDir\ss_$Name.png"
    $bytes = [Convert]::FromBase64String($b64)
    [System.IO.File]::WriteAllBytes($path, $bytes)
    return "OK: $path ($($bytes.Length) bytes)"
}

function Get-GameResources {
    $procs = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
    if (-not $procs) { return @{error="No Godot process"} }
    $result = @()
    foreach ($p in $procs) {
        $result += @{
            PID = $p.Id
            WS_MB = [math]::Round($p.WorkingSet64/1MB, 1)
            PM_MB = [math]::Round($p.PrivateMemorySize64/1MB, 1)
            CPU_s = [math]::Round($p.CPU, 1)
            Threads = $p.Threads.Count
            Handles = $p.HandleCount
        }
    }
    return $result
}

function Get-CombatStatus {
    $code = @"
var info = {"total": PawnManager.pawns.size(), "drafted": 0, "dead": 0, "downed": 0, "enemy": 0, "colonist_ok": 0}
for p in PawnManager.pawns:
    var is_enemy = p.has_meta("faction") and p.get_meta("faction") == "enemy"
    if p.dead: info.dead += 1
    elif p.downed: info.downed += 1
    elif is_enemy: info.enemy += 1
    elif p.drafted: info.drafted += 1
    else: info.colonist_ok += 1
return info
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Set-GameSpeed {
    param([int]$TPF = 30)
    $code = "TickManager._ticks_per_frame[3] = $TPF`nTickManager.set_speed(3)`nreturn TickManager._ticks_per_frame"
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Switch-ToGame {
    $code = @"
var main = get_tree().root.get_node("Main")
if main and main.has_method("switch_to_game"):
    main.switch_to_game()
    return "switched_to_game"
return "no_main"
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Invoke-Raid {
    param([int]$Count = 5)
    $code = "RaidManager.spawn_raid($Count)`nreturn ""raid_spawned"""
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Invoke-Draft {
    param([int]$Max = 10)
    $code = @"
get_tree().paused = true
var drafted = 0
for p in PawnManager.pawns:
    if drafted >= ${Max}: break
    if not p.dead and not p.downed and not p.drafted:
        if not p.has_meta("faction") or p.get_meta("faction") != "enemy":
            PawnManager.toggle_draft(p)
            drafted += 1
return {"drafted": drafted, "paused": true}
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Invoke-Undraft {
    $code = @"
var count = 0
for p in PawnManager.pawns:
    if p.drafted:
        PawnManager.toggle_draft(p)
        count += 1
get_tree().paused = false
return {"undrafted": count}
"@
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Save-Game {
    param([string]$Name)
    $code = "var map = GameState.get_map()`nif map:`n`tSaveLoad.save_game(""$Name"", map)`n`treturn ""saved""`nreturn ""no_map"""
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Test-SaveLoad {
    param([string]$Name)
    $code = "var data = SaveLoad.load_game(""$Name"")`nreturn {""ok"": not data.is_empty(), ""keys"": data.keys() if not data.is_empty() else []}"
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Place-Blueprints {
    param([int]$Count = 3, [int]$StartX = 30, [int]$Y = 30, [int]$Spacing = 2)
    $positions = ""
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $StartX + $i * $Spacing
        if ($i -gt 0) { $positions += ", " }
        $positions += "Vector2i($x,$Y)"
    }
    $code = "var created = 0`nvar positions = [$positions]`nfor pos in positions:`n`tvar b = ThingManager.place_blueprint(""Wall"", pos)`n`tif b: created += 1`nreturn {""blueprints_created"": created}"
    $r = Send-Eval -Code $code
    if ($r.success) { return $r.result } else { return $r }
}

function Start-MonitorLoop {
    param(
        [int]$IntervalSec = 10,
        [int]$Rounds = -1,
        [switch]$WithScreenshot
    )
    $i = 0
    while ($Rounds -eq -1 -or $i -lt $Rounds) {
        $i++
        $ts = Get-Date -Format "HH:mm:ss"
        Write-Host "--- Monitor #$i @ $ts ---" -ForegroundColor Cyan
        $status = Get-GameStatus
        if ($status.tick) {
            Write-Host ("  Tick:{0} Date:{1}/{2}/{3} Pawns:{4} Dead:{5} Downed:{6} Enemy:{7} FPS:{8} Temp:{9:F1}" -f `
                $status.tick, $status.year, $status.quadrum, $status.day, `
                $status.pawns, $status.dead, $status.downed, $status.enemy, `
                $status.fps, $status.temp)
        } else {
            Write-Host "  [WARN] Status query failed: $($status | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        }
        $res = Get-GameResources
        foreach ($r in $res) {
            Write-Host ("  PID:{0} WS:{1}MB PM:{2}MB CPU:{3}s Thr:{4} Hdl:{5}" -f `
                $r.PID, $r.WS_MB, $r.PM_MB, $r.CPU_s, $r.Threads, $r.Handles)
        }
        if ($WithScreenshot) {
            $ssResult = Save-GameScreenshot -Name "monitor_$i"
            Write-Host "  Screenshot: $ssResult"
        }
        if ($Rounds -ne -1 -and $i -ge $Rounds) { break }
        Start-Sleep -Seconds ([Math]::Min($IntervalSec, 10))
    }
}

function Run-AutoTest {
    param(
        [int]$Speed = 30,
        [int]$WarmupSec = 10,
        [switch]$TriggerRaid,
        [int]$RaidSize = 5,
        [string]$SaveName = "autotest",
        [int]$MonitorRounds = 3,
        [int]$MonitorInterval = 10
    )

    Write-Host "=== RimWorld AutoTest ===" -ForegroundColor Green

    # S1: 检查进程
    Write-Host "[S1] Checking Godot process..." -ForegroundColor Yellow
    $res = Get-GameResources
    Write-Host "  Processes: $($res.Count)"

    # S2: 切换到游戏
    Write-Host "[S2] Switching to game scene..." -ForegroundColor Yellow
    $sw = Switch-ToGame
    Write-Host "  Result: $sw"
    Start-Sleep -Seconds 3

    # S3: 设置速度
    Write-Host "[S3] Setting speed to $Speed tpf..." -ForegroundColor Yellow
    $spd = Set-GameSpeed -TPF $Speed
    Write-Host "  Ticks/frame: $($spd | ConvertTo-Json -Compress)"

    # S4: 初始截图
    Write-Host "[S4] Initial screenshot..." -ForegroundColor Yellow
    $ss = Save-GameScreenshot -Name "${SaveName}_start"
    Write-Host "  $ss"

    # S5: 等待预热
    Write-Host "[S5] Warmup ${WarmupSec}s..." -ForegroundColor Yellow
    Start-Sleep -Seconds ([Math]::Min($WarmupSec, 10))

    # S6: 状态查询
    Write-Host "[S6] Status check..." -ForegroundColor Yellow
    $status = Get-GameStatus
    Write-Host "  $($status | ConvertTo-Json -Compress)"

    # S7: 工作分配
    Write-Host "[S7] Job distribution..." -ForegroundColor Yellow
    $jobs = Get-JobDistribution
    Write-Host "  $($jobs | ConvertTo-Json -Compress)"

    # S8: 建造
    Write-Host "[S8] Placing blueprints..." -ForegroundColor Yellow
    $bp = Place-Blueprints -Count 3
    Write-Host "  $($bp | ConvertTo-Json -Compress)"

    # S9: 战斗 (可选)
    if ($TriggerRaid) {
        Write-Host "[S9] Triggering raid ($RaidSize)..." -ForegroundColor Yellow
        Invoke-Raid -Count $RaidSize
        Start-Sleep -Seconds 1
        Write-Host "[S9] Drafting colonists..." -ForegroundColor Yellow
        $dr = Invoke-Draft -Max 10
        Write-Host "  Drafted: $($dr | ConvertTo-Json -Compress)"
        Write-Host "[S9] Resuming game..." -ForegroundColor Yellow
        Send-Eval -Code "get_tree().paused = false; return ""resumed"""
        Start-Sleep -Seconds ([Math]::Min(10, 10))
        Write-Host "[S9] Combat status..." -ForegroundColor Yellow
        $cs = Get-CombatStatus
        Write-Host "  $($cs | ConvertTo-Json -Compress)"
        Write-Host "[S9] Undrafting..." -ForegroundColor Yellow
        $ud = Invoke-Undraft
        Write-Host "  $($ud | ConvertTo-Json -Compress)"
    }

    # S10: 存档
    Write-Host "[S10] Saving game as '$SaveName'..." -ForegroundColor Yellow
    $sv = Save-Game -Name $SaveName
    Write-Host "  Save: $sv"
    $vf = Test-SaveLoad -Name $SaveName
    Write-Host "  Verify: $($vf | ConvertTo-Json -Compress)"

    # S11: 战斗截图
    Write-Host "[S11] Final screenshot..." -ForegroundColor Yellow
    $ss2 = Save-GameScreenshot -Name "${SaveName}_final"
    Write-Host "  $ss2"

    # S12: 资源监控
    Write-Host "[S12] Resource monitor..." -ForegroundColor Yellow
    $res2 = Get-GameResources
    foreach ($r in $res2) {
        Write-Host ("  PID:{0} WS:{1}MB PM:{2}MB CPU:{3}s" -f $r.PID, $r.WS_MB, $r.PM_MB, $r.CPU_s)
    }

    # S13: 监控循环
    if ($MonitorRounds -gt 0) {
        Write-Host "[S13] Starting monitor loop ($MonitorRounds rounds)..." -ForegroundColor Yellow
        Start-MonitorLoop -IntervalSec $MonitorInterval -Rounds $MonitorRounds
    }

    Write-Host "=== AutoTest Complete ===" -ForegroundColor Green
}

Write-Host "autotest.ps1 loaded. Available commands:" -ForegroundColor Green
Write-Host "  Send-GameCmd, Send-Eval, Get-GameStatus, Get-JobDistribution"
Write-Host "  Save-GameScreenshot, Get-GameResources, Get-CombatStatus"
Write-Host "  Set-GameSpeed, Switch-ToGame, Invoke-Raid, Invoke-Draft, Invoke-Undraft"
Write-Host "  Save-Game, Test-SaveLoad, Place-Blueprints"
Write-Host "  Start-MonitorLoop, Run-AutoTest"
Write-Host ""
Write-Host "Quick start:" -ForegroundColor Cyan
Write-Host "  Run-AutoTest -Speed 30 -TriggerRaid -SaveName 'test1'"
Write-Host "  Start-MonitorLoop -IntervalSec 10 -Rounds 5 -WithScreenshot"