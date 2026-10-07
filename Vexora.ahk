; ================================================================
;  VEXORA — CS2 Macro Suite v2.7
;  AutoHotkey v2.0
; ================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

CS2_EXE     := "cs2.exe"
CONFIG_FILE := A_ScriptDir . "\vexora_config.ini"

; ── Global State ─────────────────────────────────────────────
global bhopActive       := false
global pistolActive     := false
global scopeToggled     := false
global bhopLimit        := 50
global pistolCPS        := 50
global currentTheme     := "Dark"
global currentSlot      := 2
global BOMB_TIME        := 40
global sniperVisible    := false

global bombPlanted      := false
global bombStartTick    := 0
global lastLogSize      := 0
global logFilePath      := ""

global bombPosX := 20
global bombPosY := 0
global kdPosX   := 20
global kdPosY   := 0

; ── Snap Tap State ───────────────────────────────────────────
global snapTapEnabled   := true
global snapTapW         := false
global snapTapA         := false
global snapTapS         := false
global snapTapD         := false

; ── Auto Strafe State ────────────────────────────────────────
global autoStrafeEnabled := false
global strafeInAir       := false
global strafeDir         := 1   ; 1 = right, -1 = left

; ── Utility ──────────────────────────────────────────────────
BhopDelay()   => Max(1, Round(1000 / bhopLimit))
PistolDelay() => Max(1, Round(1000 / pistolCPS))
CS2Active()   => WinActive("ahk_exe " . CS2_EXE)
CS2Running()  => ProcessExist(CS2_EXE) ? true : false

ParseInt(val) {
    c := RegExReplace(String(val), "[^\d-]", "")
    return (c = "" || c = "-") ? 0 : Integer(c)
}

; ================================================================
;  THEMES
; ================================================================
Themes := Map(
    "Dark", Map(
        "bg","0A0A12","panel","12121C","card","181822",
        "accent","6366F1","text","E5E7EB","dim","9CA3AF",
        "good","10B981","bad","EF4444","warn","F59E0B"),
    "Midnight", Map(
        "bg","0A1628","panel","0E1E35","card","152838",
        "accent","3B82F6","text","DBEAFE","dim","93C5FD",
        "good","22D3EE","bad","F87171","warn","FBBF24"),
    "Purple", Map(
        "bg","1A0B2E","panel","240E38","card","2D1B4E",
        "accent","A855F7","text","F3E8FF","dim","D8B4FE",
        "good","10B981","bad","F87171","warn","FBBF24"),
    "Emerald", Map(
        "bg","0A1F1A","panel","0E2620","card","153328",
        "accent","10B981","text","D1FAE5","dim","6EE7B7",
        "good","34D399","bad","F87171","warn","FBBF24"),
    "Crimson", Map(
        "bg","1F0A0F","panel","2A0E15","card","3D1520",
        "accent","EF4444","text","FEE2E2","dim","FCA5A5",
        "good","10B981","bad","F87171","warn","FBBF24"),
    "Frost", Map(
        "bg","F1F5F9","panel","E2E8F0","card","FFFFFF",
        "accent","0EA5E9","text","0F172A","dim","475569",
        "good","059669","bad","DC2626","warn","D97706")
)

GetTheme(n?) {
    name := n ?? currentTheme
    return Themes.Has(name) ? Themes[name] : Themes["Dark"]
}

; ================================================================
;  CONFIG SAVE / LOAD
; ================================================================
SaveConfig() {
    f := CONFIG_FILE
    IniWrite(currentTheme,           f, "General", "Theme")
    IniWrite(chkAOT.Value,           f, "General", "AlwaysOnTop")
    IniWrite(edCS2Interval.Value,    f, "General", "CS2Interval")
    IniWrite(chkAutoDisable.Value,   f, "General", "AutoDisable")

    IniWrite(chkBhop.Value,          f, "Macros", "BhopOn")
    IniWrite(edBhop.Value,           f, "Macros", "BhopRate")
    IniWrite(chkPistol.Value,        f, "Macros", "PistolOn")
    IniWrite(edPistolCPS.Value,      f, "Macros", "PistolCPS")
    IniWrite(chkScope.Value,         f, "Macros", "ScopeOn")
    IniWrite(edScopeADS.Value,       f, "Macros", "ScopeADS")
    IniWrite(edScopePost.Value,      f, "Macros", "ScopePost")
    IniWrite(edSlot1.Value,          f, "Macros", "Slot1")
    IniWrite(edSlot2.Value,          f, "Macros", "Slot2")

    IniWrite(edKeyBhop.Value,        f, "Keys", "Bhop")
    IniWrite(edKeyPistol.Value,      f, "Keys", "Pistol")
    IniWrite(edKeyScope.Value,       f, "Keys", "Scope")

    IniWrite(chkBombTimer.Value,     f, "Bomb", "Enabled")
    IniWrite(chkBombAuto.Value,      f, "Bomb", "AutoMode")
    IniWrite(edBombDur.Value,        f, "Bomb", "Duration")
    IniWrite(edBombKey.Value,        f, "Bomb", "ManualKey")
    IniWrite(edBombOpacity.Value,    f, "Bomb", "Opacity")
    IniWrite(edBombColor.Value,      f, "Bomb", "Color")
    IniWrite(bombPosX,               f, "Bomb", "PosX")
    IniWrite(bombPosY,               f, "Bomb", "PosY")
    IniWrite(chkBombLock.Value,      f, "Bomb", "Locked")

    IniWrite(chkKeyDisplay.Value,    f, "KeyDisplay", "Enabled")
    IniWrite(edKDOpacity.Value,      f, "KeyDisplay", "Opacity")
    IniWrite(edKDColor.Value,        f, "KeyDisplay", "Color")
    IniWrite(kdPosX,                 f, "KeyDisplay", "PosX")
    IniWrite(kdPosY,                 f, "KeyDisplay", "PosY")
    IniWrite(chkKDLock.Value,        f, "KeyDisplay", "Locked")

    IniWrite(chkSniper.Value,        f, "Sniper", "Enabled")
    IniWrite(edDotSize.Value,        f, "Sniper", "DotSize")
    IniWrite(edDotColor.Value,       f, "Sniper", "DotColor")
    IniWrite(edDotOpacity.Value,     f, "Sniper", "DotOpacity")
    IniWrite(edDotOutline.Value,     f, "Sniper", "OutlineSize")

    IniWrite(chkSnapTap.Value,       f, "Movement", "SnapTap")
    IniWrite(chkAutoStrafe.Value,    f, "Movement", "AutoStrafe")
    IniWrite(edStrafeRate.Value,     f, "Movement", "StrafeRate")
}

LoadConfig() {
    global currentTheme, bombPosX, bombPosY, kdPosX, kdPosY
    f := CONFIG_FILE
    if !FileExist(f)
        return

    try currentTheme         := IniRead(f, "General", "Theme", "Dark")
    try chkAOT.Value         := IniRead(f, "General", "AlwaysOnTop", 0)
    try edCS2Interval.Value  := IniRead(f, "General", "CS2Interval", "2000")
    try chkAutoDisable.Value := IniRead(f, "General", "AutoDisable", 1)

    try chkBhop.Value     := IniRead(f, "Macros", "BhopOn", 1)
    try edBhop.Value      := IniRead(f, "Macros", "BhopRate", "50")
    try chkPistol.Value   := IniRead(f, "Macros", "PistolOn", 1)
    try edPistolCPS.Value := IniRead(f, "Macros", "PistolCPS", "50")
    try chkScope.Value    := IniRead(f, "Macros", "ScopeOn", 1)
    try edScopeADS.Value  := IniRead(f, "Macros", "ScopeADS", "5")
    try edScopePost.Value := IniRead(f, "Macros", "ScopePost", "64")
    try edSlot1.Value     := IniRead(f, "Macros", "Slot1", "3")
    try edSlot2.Value     := IniRead(f, "Macros", "Slot2", "1")

    try edKeyBhop.Value   := IniRead(f, "Keys", "Bhop", "Space")
    try edKeyPistol.Value := IniRead(f, "Keys", "Pistol", "LButton")
    try edKeyScope.Value  := IniRead(f, "Keys", "Scope", "e")

    try chkBombTimer.Value  := IniRead(f, "Bomb", "Enabled", 1)
    try chkBombAuto.Value   := IniRead(f, "Bomb", "AutoMode", 1)
    try edBombDur.Value     := IniRead(f, "Bomb", "Duration", "40")
    try edBombKey.Value     := IniRead(f, "Bomb", "ManualKey", "F5")
    try edBombOpacity.Value := IniRead(f, "Bomb", "Opacity", "240")
    try edBombColor.Value   := IniRead(f, "Bomb", "Color", "FF6644")
    try bombPosX            := ParseInt(IniRead(f, "Bomb", "PosX", "20"))
    try bombPosY            := ParseInt(IniRead(f, "Bomb", "PosY", A_ScreenHeight - 220))
    try chkBombLock.Value   := IniRead(f, "Bomb", "Locked", 0)

    try chkKeyDisplay.Value := IniRead(f, "KeyDisplay", "Enabled", 0)
    try edKDOpacity.Value   := IniRead(f, "KeyDisplay", "Opacity", "230")
    try edKDColor.Value     := IniRead(f, "KeyDisplay", "Color", "FF3366")
    try kdPosX              := ParseInt(IniRead(f, "KeyDisplay", "PosX", "20"))
    try kdPosY              := ParseInt(IniRead(f, "KeyDisplay", "PosY", A_ScreenHeight - 400))
    try chkKDLock.Value     := IniRead(f, "KeyDisplay", "Locked", 0)

    try chkSniper.Value    := IniRead(f, "Sniper", "Enabled", 0)
    try edDotSize.Value    := IniRead(f, "Sniper", "DotSize", "4")
    try edDotColor.Value   := IniRead(f, "Sniper", "DotColor", "000000")
    try edDotOpacity.Value := IniRead(f, "Sniper", "DotOpacity", "255")
    try edDotOutline.Value := IniRead(f, "Sniper", "OutlineSize", "1")

    try chkSnapTap.Value    := IniRead(f, "Movement", "SnapTap", 1)
    try chkAutoStrafe.Value := IniRead(f, "Movement", "AutoStrafe", 0)
    try edStrafeRate.Value  := IniRead(f, "Movement", "StrafeRate", "25")

    ; Sync global snap tap state from checkbox
    global snapTapEnabled
    try snapTapEnabled := chkSnapTap.Value

    themes := ["Dark", "Midnight", "Purple", "Emerald", "Crimson", "Frost"]
    for i, name in themes {
        if (name = currentTheme) {
            ddTheme.Choose(i)
            break
        }
    }
    if chkAOT.Value
        MyGui.Opt("+AlwaysOnTop")
}

; ================================================================
;  BOMB TIMER OVERLAY
; ================================================================
global BombGui       := 0
global bombTimeCtrl  := 0
global bombBarCtrl   := 0
global bombLabelCtrl := 0
global bombC4Ctrl    := 0
global bombSecCtrl   := 0

CreateBombGui() {
    global BombGui, bombTimeCtrl, bombBarCtrl, bombLabelCtrl, bombC4Ctrl, bombSecCtrl

    userColor := Trim(edBombColor.Value)
    if (userColor = "")
        userColor := "FF6644"

    BombGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000")
    BombGui.BackColor := "0A0A0F"
    BombGui.MarginX := 0
    BombGui.MarginY := 0

    BombGui.Add("Text", "x0 y0 w260 h3 Background" . userColor)
    BombGui.Add("Text", "x0 y3 w260 h28 Background151520")

    BombGui.SetFont("s14 cFFFFFF Bold", "Segoe UI Emoji")
    bombC4Ctrl := BombGui.Add("Text", "x10 y5 w26 h24 Center BackgroundTrans", "💣")

    BombGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
    bombLabelCtrl := BombGui.Add("Text", "x40 y8 w150 h18 Left BackgroundTrans", "BOMB PLANTED")

    BombGui.SetFont("s8 c" . userColor . " Bold", "Consolas")
    BombGui.Add("Text", "x200 y8 w50 h18 Right BackgroundTrans", "◉ LIVE")

    BombGui.Add("Text", "x0 y31 w260 h60 Background0A0A0F")

    BombGui.SetFont("s36 cFFFFFF Bold", "Consolas")
    bombTimeCtrl := BombGui.Add("Text", "x10 y33 w170 h55 Left BackgroundTrans", "40.0")

    BombGui.SetFont("s11 c888888 Bold", "Consolas")
    bombSecCtrl := BombGui.Add("Text", "x180 y58 w70 h20 Left BackgroundTrans", "SEC")

    BombGui.Add("Text", "x0 y91 w260 h4 Background1A1A25")
    bombBarCtrl := BombGui.Add("Progress",
        "x0 y91 w260 h4 c" . userColor . " Background1A1A25 -Smooth Range0-1000", 1000)

    BombGui.Add("Text", "x0 y95 w260 h20 Background0F0F16")
    BombGui.SetFont("s7 c666677", "Consolas")
    BombGui.Add("Text", "x10 y98 w130 h14 Left BackgroundTrans", "⏱ C4 COUNTDOWN")
    BombGui.Add("Text", "x140 y98 w110 h14 Right BackgroundTrans", "VEXORA v2.6")

    bombC4Ctrl.OnEvent("Click", BombDrag)
    bombTimeCtrl.OnEvent("Click", BombDrag)
    bombLabelCtrl.OnEvent("Click", BombDrag)
    bombSecCtrl.OnEvent("Click", BombDrag)

    BombGui.OnEvent("ContextMenu", HideBombTimerCtx)
}

BombDrag(*) {
    if !chkBombLock.Value
        PostMessage(0xA1, 2, 0, , "ahk_id " . BombGui.Hwnd)
}

HideBombTimerCtx(*) {
    HideBombTimer()
}

ShowBombTimer() {
    global BombGui, bombPosX, bombPosY
    if !chkBombTimer.Value
        return
    if !BombGui
        CreateBombGui()

    opacity := ParseInt(edBombOpacity.Value)
    opacity := Max(50, Min(255, opacity))

    userColor := Trim(edBombColor.Value)
    if (userColor = "")
        userColor := "FF6644"

    try bombBarCtrl.Opt("+c" . userColor)
    bombBarCtrl.Value := 1000
    bombTimeCtrl.Value := Format("{:.1f}", BOMB_TIME)
    bombTimeCtrl.SetFont("s36 cFFFFFF Bold")
    bombLabelCtrl.Value := "BOMB PLANTED"
    bombLabelCtrl.SetFont("s10 cFFFFFF Bold")
    bombSecCtrl.SetFont("s11 c888888 Bold")

    posX := bombPosX
    posY := bombPosY
    if (posY = 0)
        posY := A_ScreenHeight - 220

    WinSetTransparent(opacity, BombGui)
    BombGui.Show("x" . posX . " y" . posY . " w260 h115 NoActivate")
    SetTimer(TrackBombPos, 500)
}

HideBombTimer() {
    global BombGui
    SetTimer(TrackBombPos, 0)
    if BombGui
        BombGui.Hide()
}

TrackBombPos(*) {
    global BombGui, bombPosX, bombPosY
    if !BombGui || !BombGui.Hwnd
        return
    try {
        BombGui.GetPos(&x, &y)
        if (x != bombPosX || y != bombPosY) {
            bombPosX := x
            bombPosY := y
            try edBombX.Value := x
            try edBombY.Value := y
            IniWrite(x, CONFIG_FILE, "Bomb", "PosX")
            IniWrite(y, CONFIG_FILE, "Bomb", "PosY")
        }
    }
}

UpdateBombTimer(*) {
    global bombPlanted, bombStartTick, BOMB_TIME
    if !bombPlanted {
        SetTimer(UpdateBombTimer, 0)
        HideBombTimer()
        return
    }

    elapsed   := (A_TickCount - bombStartTick) / 1000
    remaining := BOMB_TIME - elapsed

    if (remaining <= 0) {
        bombPlanted := false
        SetTimer(UpdateBombTimer, 0)
        bombTimeCtrl.Value := "0.0"
        bombTimeCtrl.SetFont("s36 cFF3333 Bold")
        bombLabelCtrl.Value := "💥 DETONATED"
        bombLabelCtrl.SetFont("s10 cFF3333 Bold")
        bombBarCtrl.Value := 0
        SetTimer(HideBombTimer, -2500)
        return
    }

    pct := Round((remaining / BOMB_TIME) * 1000)
    bombBarCtrl.Value := pct
    bombTimeCtrl.Value := Format("{:.1f}", remaining)

    if (remaining <= 5) {
        bombTimeCtrl.SetFont("s36 cFF3333 Bold")
        try bombBarCtrl.Opt("+cFF3333")
        bombLabelCtrl.Value := "⚠ DETONATING"
        bombLabelCtrl.SetFont("s10 cFF3333 Bold")
        bombSecCtrl.SetFont("s11 cFF6666 Bold")
    } else if (remaining <= 15) {
        bombTimeCtrl.SetFont("s36 cFFB844 Bold")
        try bombBarCtrl.Opt("+cFFB844")
        bombLabelCtrl.Value := "⏰ HURRY UP"
        bombLabelCtrl.SetFont("s10 cFFB844 Bold")
        bombSecCtrl.SetFont("s11 cFFAA55 Bold")
    } else {
        bombTimeCtrl.SetFont("s36 cFFFFFF Bold")
        userColor := Trim(edBombColor.Value)
        if (userColor = "")
            userColor := "FF6644"
        try bombBarCtrl.Opt("+c" . userColor)
        bombLabelCtrl.Value := "💣 BOMB PLANTED"
        bombLabelCtrl.SetFont("s10 cFFFFFF Bold")
        bombSecCtrl.SetFont("s11 c888888 Bold")
    }
}

StartBomb(*) {
    global bombPlanted, bombStartTick, BOMB_TIME
    BOMB_TIME := ParseInt(edBombDur.Value)
    if (BOMB_TIME < 5)
        BOMB_TIME := 40
    bombPlanted   := true
    bombStartTick := A_TickCount
    ShowBombTimer()
    SetTimer(UpdateBombTimer, 50)
}

StopBomb(*) {
    global bombPlanted
    bombPlanted := false
    SetTimer(UpdateBombTimer, 0)
    HideBombTimer()
}

ManualBombToggle(*) {
    global bombPlanted
    if !CS2Active()
        return
    if bombPlanted
        StopBomb()
    else
        StartBomb()
}

; ================================================================
;  AUTO BOMB DETECTION
; ================================================================
FindLogFile() {
    global logFilePath
    paths := [
        A_ProgramFiles . "\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log",
        "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log",
        "D:\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log",
        "D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log",
        "E:\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log",
        "E:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\csgo\console.log"
    ]
    for p in paths {
        if FileExist(p) {
            logFilePath := p
            return true
        }
    }
    return false
}

PollBombLog(*) {
    global bombPlanted, lastLogSize, logFilePath
    if !chkBombAuto.Value || !chkBombTimer.Value || !CS2Running()
        return
    if (logFilePath = "" || !FileExist(logFilePath))
        if !FindLogFile()
            return

    try {
        fileSize := FileGetSize(logFilePath)
        if (fileSize < lastLogSize)
            lastLogSize := 0
        if (fileSize <= lastLogSize)
            return

        f := FileOpen(logFilePath, "r")
        if !f
            return
        if (lastLogSize > 0)
            f.Seek(lastLogSize)
        chunk := f.Read()
        f.Close()
        lastLogSize := fileSize

        if (InStr(chunk, "planted the bomb") || InStr(chunk, "bomb_planted")) {
            if !bombPlanted
                StartBomb()
        }
        if (InStr(chunk, "bomb_defused") || InStr(chunk, "defused the bomb")
            || InStr(chunk, "bomb_exploded") || InStr(chunk, "round_end")) {
            if bombPlanted
                StopBomb()
        }
    }
}

; ================================================================
;  KEY DISPLAY OVERLAY
; ================================================================
global KeyGui := 0
global keyCtrls := Map()
global keyBgCtrls := Map()
global keyStates := Map(
    "W", false, "A", false, "S", false, "D", false,
    "LMB", false, "RMB", false
)

CreateKeyDisplay() {
    global KeyGui, keyCtrls, keyBgCtrls
    userColor := Trim(edKDColor.Value)
    if (userColor = "")
        userColor := "FF3366"

    KeyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000")
    KeyGui.BackColor := "0A0A0F"
    KeyGui.MarginX := 0
    KeyGui.MarginY := 0

    KeyGui.Add("Text", "x0 y0 w180 h2 Background" . userColor)
    KeyGui.Add("Text", "x0 y2 w180 h22 Background151520")
    KeyGui.SetFont("s8 cFFFFFF Bold", "Segoe UI")
    KeyGui.Add("Text", "x0 y6 w180 h14 Center BackgroundTrans", "⌨ KEYSTROKES")

    KeyGui.SetFont("s16 cFFFFFF Bold", "Segoe UI")

    keyBgCtrls["W"] := KeyGui.Add("Text", "x69 y30 w42 h42 Background1A1A25 Border")
    keyCtrls["W"]   := KeyGui.Add("Text", "x69 y30 w42 h42 Center BackgroundTrans cFFFFFF", "W")

    keyBgCtrls["A"] := KeyGui.Add("Text", "x25 y76 w42 h42 Background1A1A25 Border")
    keyCtrls["A"]   := KeyGui.Add("Text", "x25 y76 w42 h42 Center BackgroundTrans cFFFFFF", "A")

    keyBgCtrls["S"] := KeyGui.Add("Text", "x69 y76 w42 h42 Background1A1A25 Border")
    keyCtrls["S"]   := KeyGui.Add("Text", "x69 y76 w42 h42 Center BackgroundTrans cFFFFFF", "S")

    keyBgCtrls["D"] := KeyGui.Add("Text", "x113 y76 w42 h42 Background1A1A25 Border")
    keyCtrls["D"]   := KeyGui.Add("Text", "x113 y76 w42 h42 Center BackgroundTrans cFFFFFF", "D")

    KeyGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
    keyBgCtrls["LMB"] := KeyGui.Add("Text", "x25 y122 w64 h26 Background1A1A25 Border")
    keyCtrls["LMB"]   := KeyGui.Add("Text", "x25 y122 w64 h26 Center BackgroundTrans cFFFFFF", "LMB")

    keyBgCtrls["RMB"] := KeyGui.Add("Text", "x91 y122 w64 h26 Background1A1A25 Border")
    keyCtrls["RMB"]   := KeyGui.Add("Text", "x91 y122 w64 h26 Center BackgroundTrans cFFFFFF", "RMB")

    for name, ctrl in keyCtrls
        ctrl.OnEvent("Click", KDDrag)
    for name, ctrl in keyBgCtrls
        ctrl.OnEvent("Click", KDDrag)

    KeyGui.OnEvent("ContextMenu", HideKDCtx)
}

KDDrag(*) {
    if !chkKDLock.Value
        PostMessage(0xA1, 2, 0, , "ahk_id " . KeyGui.Hwnd)
}

HideKDCtx(*) {
    chkKeyDisplay.Value := 0
    HideKeyDisplay()
}

ShowKeyDisplay() {
    global KeyGui, kdPosX, kdPosY
    if !KeyGui
        CreateKeyDisplay()

    opacity := ParseInt(edKDOpacity.Value)
    opacity := Max(50, Min(255, opacity))

    posX := kdPosX
    posY := kdPosY
    if (posY = 0)
        posY := A_ScreenHeight - 400

    WinSetTransparent(opacity, KeyGui)
    KeyGui.Show("x" . posX . " y" . posY . " w180 h156 NoActivate")
    SetTimer(UpdateKeyDisplay, 16)
    SetTimer(TrackKDPos, 500)
}

HideKeyDisplay() {
    global KeyGui
    SetTimer(UpdateKeyDisplay, 0)
    SetTimer(TrackKDPos, 0)
    if KeyGui
        KeyGui.Hide()
}

TrackKDPos(*) {
    global KeyGui, kdPosX, kdPosY
    if !KeyGui || !KeyGui.Hwnd
        return
    try {
        KeyGui.GetPos(&x, &y)
        if (x != kdPosX || y != kdPosY) {
            kdPosX := x
            kdPosY := y
            try edKDX.Value := x
            try edKDY.Value := y
            IniWrite(x, CONFIG_FILE, "KeyDisplay", "PosX")
            IniWrite(y, CONFIG_FILE, "KeyDisplay", "PosY")
        }
    }
}

UpdateKeyDisplay(*) {
    global keyCtrls, keyBgCtrls, keyStates
    if !chkKeyDisplay.Value {
        HideKeyDisplay()
        return
    }

    userColor := Trim(edKDColor.Value)
    if (userColor = "")
        userColor := "FF3366"

    check := Map(
        "W", GetKeyState("w", "P"),
        "A", GetKeyState("a", "P"),
        "S", GetKeyState("s", "P"),
        "D", GetKeyState("d", "P"),
        "LMB", GetKeyState("LButton", "P"),
        "RMB", GetKeyState("RButton", "P")
    )

    for name, pressed in check {
        if (keyStates[name] != pressed) {
            keyStates[name] := pressed
            try {
                if pressed {
                    keyBgCtrls[name].Opt("+Background" . userColor)
                    keyCtrls[name].Opt("+c000000")
                } else {
                    keyBgCtrls[name].Opt("+Background1A1A25")
                    keyCtrls[name].Opt("+cFFFFFF")
                }
                keyBgCtrls[name].Redraw()
                keyCtrls[name].Redraw()
            }
        }
    }
}

; ================================================================
;  ★ SNIPER DOT CROSSHAIR — черная точка в центре
;  Работает ТОЛЬКО на слоте 1 (главное оружие)
; ================================================================
global SniperGui := 0

CreateSniperDot() {
    global SniperGui

    dotSize    := ParseInt(edDotSize.Value)
    outline    := ParseInt(edDotOutline.Value)
    dotColor   := Trim(edDotColor.Value)
    opacity    := ParseInt(edDotOpacity.Value)

    if (dotSize < 2)
        dotSize := 4
    if (outline < 0)
        outline := 1
    if (dotColor = "")
        dotColor := "000000"

    ; Общий размер окна = точка + обводка + запас
    totalSize := dotSize + (outline * 2) + 4

    SniperGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000020 +LastFound")
    SniperGui.BackColor := "FF00FF"  ; magenta = будет прозрачным
    SniperGui.MarginX := 0
    SniperGui.MarginY := 0
    WinSetTransColor("FF00FF", SniperGui)

    cx := totalSize / 2
    cy := totalSize / 2

    ; Обводка (белая или своя) — рисуем как фон немного больше
    if (outline > 0) {
        outlineColor := "FFFFFF"
        outlineTotal := dotSize + (outline * 2)
        SniperGui.Add("Text",
            "x" . (cx - outlineTotal/2) . " y" . (cy - outlineTotal/2)
            . " w" . outlineTotal . " h" . outlineTotal
            . " Background" . outlineColor)
    }

    ; Точка (сверху обводки)
    SniperGui.Add("Text",
        "x" . (cx - dotSize/2) . " y" . (cy - dotSize/2)
        . " w" . dotSize . " h" . dotSize
        . " Background" . dotColor)

    ; Центр экрана
    posX := (A_ScreenWidth - totalSize) / 2
    posY := (A_ScreenHeight - totalSize) / 2

    opacity := Max(50, Min(255, opacity))

    SniperGui.Show("x" . posX . " y" . posY . " w" . totalSize . " h" . totalSize . " NoActivate")
    WinSetTransparent(opacity, SniperGui)
}

ShowSniper() {
    global sniperVisible
    if sniperVisible
        return
    if !chkSniper.Value
        return
    CreateSniperDot()
    sniperVisible := true
}

HideSniper() {
    global SniperGui, sniperVisible
    if SniperGui {
        try SniperGui.Destroy()
        SniperGui := 0
    }
    sniperVisible := false
}

CheckSniperState(*) {
    global sniperVisible

    if !chkSniper.Value {
        if sniperVisible
            HideSniper()
        return
    }

    if !CS2Active() {
        if sniperVisible
            HideSniper()
        return
    }

    ; Точка показывается ТОЛЬКО на слоте 1 (главное оружие)
    if (currentSlot = 1) {
        if !sniperVisible
            ShowSniper()
    } else {
        if sniperVisible
            HideSniper()
    }
}

RefreshSniper(*) {
    global sniperVisible
    if sniperVisible {
        HideSniper()
        Sleep 50
        ShowSniper()
    }
}

PreviewSniper(*) {
    global sniperVisible
    wasVisible := sniperVisible
    if !sniperVisible
        ShowSniper()
    SetTimer(HidePreviewSniper.Bind(wasVisible), -5000)
}

HidePreviewSniper(wasVisible, *) {
    if !wasVisible
        HideSniper()
}

; ================================================================
;  SLOT TRACKING
; ================================================================
TrackSlot1(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 1
}

TrackSlot2(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 2
}

TrackSlot3(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 3
}

TrackSlot4(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 4
}

TrackSlot5(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 5
}

TrackQ(*) {
    global currentSlot
    if CS2Active()
        currentSlot := 0
}

SetupSlotTracking() {
    try {
        HotIfWinActive "ahk_exe " . CS2_EXE
        Hotkey "~1", TrackSlot1, "On"
        Hotkey "~2", TrackSlot2, "On"
        Hotkey "~3", TrackSlot3, "On"
        Hotkey "~4", TrackSlot4, "On"
        Hotkey "~5", TrackSlot5, "On"
        Hotkey "~q", TrackQ, "On"
        HotIfWinActive
    }
}

IsPistolSlot() => (currentSlot = 2)

; ================================================================
;  MAIN GUI
; ================================================================
W := 500
H := 720
Pad := 24

MyGui := Gui("+Resize -MaximizeBox", "Vexora v2.6")
MyGui.BackColor := "0A0A12"
MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
MyGui.OnEvent("Close", ExitCleanup)

MyGui.Add("Text", "x0 y0 w" . W . " h72 Background0D0D16")
MyGui.Add("Text", "x0 y70 w" . W . " h2 Background6366F1")

MyGui.SetFont("s20 cFFFFFF Bold", "Segoe UI")
titleCtrl := MyGui.Add("Text", "x" . Pad . " y14 w200 h32 BackgroundTrans", "VEXORA")

MyGui.SetFont("s8 c6366F1 Bold", "Segoe UI")
subtitleCtrl := MyGui.Add("Text", "x" . Pad . " y46 BackgroundTrans", "CS2 MACRO SUITE")

MyGui.SetFont("s7 c6B7280", "Segoe UI")
versionCtrl := MyGui.Add("Text", "x" . (W-80) . " y18 w60 Right BackgroundTrans", "v2.7")

MyGui.SetFont("s8 c9CA3AF Bold", "Segoe UI")
MyGui.Add("Text", "x" . (W-200) . " y46 w50 BackgroundTrans", "STATUS:")
lblCS2 := MyGui.Add("Text", "x" . (W-148) . " y46 w140 BackgroundTrans", "...")

tabs := MyGui.Add("Tab3", "x0 y72 w" . W . " h600 Choose1",
    ["  Macros  ", "  Movement  ", "  Overlays  ", "  Crosshair  ", "  Settings  "])

; ═══ TAB 1: MACROS ═══
tabs.UseTab(1)
LY := 110

DrawCard(Pad, LY, W - Pad*2, 80, "BHOP", "Automated bunny hop")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkBhop := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w200", "  Enable")
chkBhop.Value := 1

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+220) . " y" . (LY+3) . " w80 Right BackgroundTrans", "Rate:")
edBhop := MyGui.Add("Edit", "x" . (Pad+305) . " y" . LY . " w70 h22 Center Background0F0F18 cE5E7EB", "50")
MyGui.Add("UpDown", "Range1-200", 50)
MyGui.SetFont("s7 c6B7280", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+380) . " y" . (LY+3) . " w40 BackgroundTrans", "j/sec")

LY += 55

DrawCard(Pad, LY, W - Pad*2, 80, "AUTO PISTOL", "Fast pistol clicking (slot 2 only)")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkPistol := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w200", "  Enable")
chkPistol.Value := 1

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+220) . " y" . (LY+3) . " w80 Right BackgroundTrans", "CPS:")
edPistolCPS := MyGui.Add("Edit", "x" . (Pad+305) . " y" . LY . " w70 h22 Center Background0F0F18 cE5E7EB", "50")
MyGui.Add("UpDown", "Range1-100", 50)
MyGui.SetFont("s7 c6B7280", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+380) . " y" . (LY+3) . " w40 BackgroundTrans", "c/sec")

LY += 55

DrawCard(Pad, LY, W - Pad*2, 130, "FAST SCOPE", "Quick scope + weapon swap")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkScope := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w200", "  Enable")
chkScope.Value := 1
LY += 30

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "ADS delay")
edScopeADS := MyGui.Add("Edit", "x" . (Pad+150) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "5")
MyGui.Add("UpDown", "Range1-500", 5)

MyGui.Add("Text", "x" . (Pad+240) . " y" . LY . " BackgroundTrans", "Post-fire")
edScopePost := MyGui.Add("Edit", "x" . (Pad+320) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "64")
MyGui.Add("UpDown", "Range1-500", 64)
LY += 28

MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Swap slot")
edSlot1 := MyGui.Add("Edit", "x" . (Pad+150) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "3")

MyGui.Add("Text", "x" . (Pad+240) . " y" . LY . " BackgroundTrans", "Return slot")
edSlot2 := MyGui.Add("Edit", "x" . (Pad+320) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "1")

; ═══ TAB 2: MOVEMENT (Snap Tap + Auto Strafe) ═══
tabs.UseTab(2)
LY := 110

DrawCard(Pad, LY, W - Pad*2, 180, "SNAP TAP", "Counter-strafe automation (WASD)")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkSnapTap := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w250", "  Enable Snap Tap (W A S D)")
chkSnapTap.Value := 1
chkSnapTap.OnEvent("Click", ToggleSnapTap)
LY += 28

; Snap Tap ON/OFF indicator — permanent
MyGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " w80 BackgroundTrans", "Status:")
snapTapIndicator := MyGui.Add("Text", "x" . (Pad+95) . " y" . LY . " w160 BackgroundTrans", "● SNAP TAP: ON")
snapTapIndicator.SetFont("s9 c10B981 Bold")
LY += 28

MyGui.SetFont("s7 c6B7280", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " w" . (W-Pad*2-24) . " BackgroundTrans",
    "▸ При нажатии противоположной клавиши — предыдущая автоматически отпускается`n"
  . "▸ W↔S и A↔D работают независимо`n"
  . "▸ F8 — переключить Snap Tap (ON/OFF)`n"
  . "▸ Работает только когда CS2 активен")
LY += 68

DrawCard(Pad, LY, W - Pad*2, 130, "AUTO STRAFE", "Автоматический воздушный стрейф")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkAutoStrafe := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w250", "  Enable Auto Strafe (в воздухе)")
chkAutoStrafe.Value := 0
chkAutoStrafe.OnEvent("Click", ToggleAutoStrafe)
LY += 28

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Strafe rate (ms)")
edStrafeRate := MyGui.Add("Edit", "x" . (Pad+140) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "25")
MyGui.Add("UpDown", "Range5-200", 25)
LY += 28

MyGui.SetFont("s7 c6B7280", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " w" . (W-Pad*2-24) . " BackgroundTrans",
    "▸ Автоматически переключает A/D в воздухе для velocity-strafe`n"
  . "▸ Требует sv_enablebunnyhopping 1 на сервере`n"
  . "▸ Используй вместе с BHOP для максимальной скорости")

; ═══ TAB 3: OVERLAYS ═══
tabs.UseTab(3)
LY := 110

DrawCard(Pad, LY, W - Pad*2, 210, "BOMB TIMER", "Auto & manual bomb countdown")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkBombTimer := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w130", "  Enable")
chkBombTimer.Value := 1
chkBombAuto := MyGui.Add("CheckBox", "x" . (Pad+150) . " y" . LY . " w140", "  Auto-detect")
chkBombAuto.Value := 1
chkBombLock := MyGui.Add("CheckBox", "x" . (Pad+300) . " y" . LY . " w100", "  Lock")
LY += 30

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Duration")
edBombDur := MyGui.Add("Edit", "x" . (Pad+90) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "40")
MyGui.Add("UpDown", "Range5-90", 40)

MyGui.Add("Text", "x" . (Pad+165) . " y" . LY . " BackgroundTrans", "Opacity")
edBombOpacity := MyGui.Add("Edit", "x" . (Pad+230) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "240")
MyGui.Add("UpDown", "Range50-255", 240)

MyGui.Add("Text", "x" . (Pad+305) . " y" . LY . " BackgroundTrans", "Key")
edBombKey := MyGui.Add("Edit", "x" . (Pad+335) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "F5")
LY += 28

MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Color")
edBombColor := MyGui.Add("Edit", "x" . (Pad+90) . " y" . (LY-3) . " w80 h22 Center Background0F0F18 cE5E7EB", "FF6644")

MyGui.Add("Text", "x" . (Pad+190) . " y" . LY . " BackgroundTrans", "X")
edBombX := MyGui.Add("Edit", "x" . (Pad+210) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "20")

MyGui.Add("Text", "x" . (Pad+280) . " y" . LY . " BackgroundTrans", "Y")
edBombY := MyGui.Add("Edit", "x" . (Pad+300) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "800")
LY += 32

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Presets:")
btnBombCenter := MyGui.Add("Button", "x" . (Pad+70) . " y" . (LY-4) . " w70 h24", "Top")
btnBombCenter.OnEvent("Click", BombPosTop)
btnBombBL := MyGui.Add("Button", "x" . (Pad+145) . " y" . (LY-4) . " w90 h24", "Bottom Left")
btnBombBL.OnEvent("Click", BombPosBL)
btnBombBR := MyGui.Add("Button", "x" . (Pad+240) . " y" . (LY-4) . " w95 h24", "Bottom Right")
btnBombBR.OnEvent("Click", BombPosBR)
LY += 34

btnTestBomb := MyGui.Add("Button", "x" . (Pad+12) . " y" . LY . " w110 h28", "Test")
btnTestBomb.OnEvent("Click", StartBombBtn)
btnStopBomb := MyGui.Add("Button", "x" . (Pad+130) . " y" . LY . " w110 h28", "Stop")
btnStopBomb.OnEvent("Click", StopBombBtn)

LY += 45

DrawCard(Pad, LY, W - Pad*2, 160, "KEYSTROKES", "WASD + LMB/RMB overlay")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkKeyDisplay := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w150", "  Enable overlay")
chkKeyDisplay.Value := 0
chkKeyDisplay.OnEvent("Click", ToggleKDCheck)

chkKDLock := MyGui.Add("CheckBox", "x" . (Pad+170) . " y" . LY . " w100", "  Lock")
LY += 30

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Opacity")
edKDOpacity := MyGui.Add("Edit", "x" . (Pad+75) . " y" . (LY-3) . " w60 h22 Center Background0F0F18 cE5E7EB", "230")
MyGui.Add("UpDown", "Range50-255", 230)

MyGui.Add("Text", "x" . (Pad+150) . " y" . LY . " BackgroundTrans", "Color")
edKDColor := MyGui.Add("Edit", "x" . (Pad+200) . " y" . (LY-3) . " w80 h22 Center Background0F0F18 cE5E7EB", "FF3366")

MyGui.Add("Text", "x" . (Pad+295) . " y" . LY . " BackgroundTrans", "X")
edKDX := MyGui.Add("Edit", "x" . (Pad+315) . " y" . (LY-3) . " w45 h22 Center Background0F0F18 cE5E7EB", "20")

MyGui.Add("Text", "x" . (Pad+370) . " y" . LY . " BackgroundTrans", "Y")
edKDY := MyGui.Add("Edit", "x" . (Pad+390) . " y" . (LY-3) . " w45 h22 Center Background0F0F18 cE5E7EB", "600")
LY += 32

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Colors:")

presets := ["FF3366", "FF6644", "FFB844", "34D399", "3FA9F5", "A855F7", "FFFFFF"]
px := Pad + 60
for i, hex in presets {
    swatch := MyGui.Add("Text", "x" . px . " y" . (LY-3) . " w24 h22 Background" . hex . " Border")
    swatch.OnEvent("Click", KDPresetHandler.Bind(hex))
    px += 28
}
LY += 30

btnKDBL := MyGui.Add("Button", "x" . (Pad+12) . " y" . LY . " w90 h24", "Bottom Left")
btnKDBL.OnEvent("Click", KDPosBL)
btnKDBR := MyGui.Add("Button", "x" . (Pad+107) . " y" . LY . " w95 h24", "Bottom Right")
btnKDBR.OnEvent("Click", KDPosBR)
btnKDCenter := MyGui.Add("Button", "x" . (Pad+207) . " y" . LY . " w110 h24", "Bottom Center")
btnKDCenter.OnEvent("Click", KDPosBC)

; ═══ TAB 4: CROSSHAIR (Sniper Dot) ═══
tabs.UseTab(4)
LY := 110

DrawCard(Pad, LY, W - Pad*2, 280, "DOT CROSSHAIR", "Small black dot for main weapon (slot 1)")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkSniper := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w300", "  Enable dot crosshair (slot 1 only)")
chkSniper.Value := 0
LY += 30

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Dot size (px)")
edDotSize := MyGui.Add("Edit", "x" . (Pad+110) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "4")
MyGui.Add("UpDown", "Range2-30", 4)

MyGui.Add("Text", "x" . (Pad+200) . " y" . LY . " BackgroundTrans", "Outline (px)")
edDotOutline := MyGui.Add("Edit", "x" . (Pad+280) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "1")
MyGui.Add("UpDown", "Range0-5", 1)
LY += 28

MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Dot color (hex)")
edDotColor := MyGui.Add("Edit", "x" . (Pad+110) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "000000")

MyGui.Add("Text", "x" . (Pad+200) . " y" . LY . " BackgroundTrans", "Opacity")
edDotOpacity := MyGui.Add("Edit", "x" . (Pad+280) . " y" . (LY-3) . " w70 h22 Center Background0F0F18 cE5E7EB", "255")
MyGui.Add("UpDown", "Range50-255", 255)
LY += 32

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Quick colors:")

dotPresets := ["000000", "FFFFFF", "00FF00", "FF0000", "00FFFF", "FFFF00", "FF00FF"]
px := Pad + 100
for i, hex in dotPresets {
    swatch := MyGui.Add("Text", "x" . px . " y" . (LY-3) . " w24 h22 Background" . hex . " Border")
    swatch.OnEvent("Click", DotPresetHandler.Bind(hex))
    px += 28
}
LY += 34

btnPreviewDot := MyGui.Add("Button", "x" . (Pad+12) . " y" . LY . " w130 h30", "Preview (5s)")
btnPreviewDot.OnEvent("Click", PreviewSniper)

btnRefreshDot := MyGui.Add("Button", "x" . (Pad+150) . " y" . LY . " w130 h30", "Refresh")
btnRefreshDot.OnEvent("Click", RefreshDotEvt)
LY += 44

MyGui.SetFont("s7 c6B7280", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " w440 BackgroundTrans",
    "▸ Small dot appears in screen center`n"
    . "▸ Only active on SLOT 1 (main weapon)`n"
    . "▸ Hides on slot 2, 3, 4, 5 automatically`n"
    . "▸ Recommended: black dot with white outline`n"
    . "▸ Click Refresh after changing settings")

; ═══ TAB 5: SETTINGS ═══
tabs.UseTab(5)
LY := 110

DrawCard(Pad, LY, W - Pad*2, 120, "GENERAL", "General settings")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
chkAOT := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w200", "  Always on top")
chkAOT.OnEvent("Click", ToggleAOT)
LY += 26

chkAutoDisable := MyGui.Add("CheckBox", "x" . (Pad+12) . " y" . LY . " w300", "  Pause when CS2 not focused")
chkAutoDisable.Value := 1
LY += 30

MyGui.SetFont("s8 c9CA3AF", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "CS2 check (ms)")
edCS2Interval := MyGui.Add("Edit", "x" . (Pad+140) . " y" . (LY-3) . " w80 h22 Center Background0F0F18 cE5E7EB", "2000")
MyGui.Add("UpDown", "Range500-10000", 2000)
LY += 38

DrawCard(Pad, LY, W - Pad*2, 60, "THEME", "Choose color scheme")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Scheme")
ddTheme := MyGui.Add("DropDownList", "x" . (Pad+130) . " y" . (LY-3) . " w160 Choose1",
    ["Dark", "Midnight", "Purple", "Emerald", "Crimson", "Frost"])
ddTheme.OnEvent("Change", ThemeChanged)
LY += 40

DrawCard(Pad, LY, W - Pad*2, 100, "HOTKEYS", "Keybind configuration")
LY += 34

MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Bhop")
edKeyBhop := MyGui.Add("Edit", "x" . (Pad+80) . " y" . (LY-3) . " w120 h22 Center Background0F0F18 cE5E7EB", "Space")

MyGui.Add("Text", "x" . (Pad+220) . " y" . LY . " BackgroundTrans", "Pistol")
edKeyPistol := MyGui.Add("Edit", "x" . (Pad+270) . " y" . (LY-3) . " w120 h22 Center Background0F0F18 cE5E7EB", "LButton")
LY += 30

MyGui.Add("Text", "x" . (Pad+12) . " y" . LY . " BackgroundTrans", "Scope")
edKeyScope := MyGui.Add("Edit", "x" . (Pad+80) . " y" . (LY-3) . " w120 h22 Center Background0F0F18 cE5E7EB", "e")

LY += 44

DrawCard(Pad, LY, W - Pad*2, 70, "SAVE EVERYTHING", "One-click save + apply all")
LY += 32

btnSave := MyGui.Add("Button", "x" . (Pad+12) . " y" . LY . " w200 h34", "SAVE && APPLY ALL")
btnSave.OnEvent("Click", SaveAndApply)

btnReset := MyGui.Add("Button", "x" . (Pad+220) . " y" . LY . " w120 h34", "Reset")
btnReset.OnEvent("Click", ResetConfig)

tabs.UseTab(0)

MyGui.SetFont("s8 c6B7280", "Segoe UI")
lblStatus := MyGui.Add("Text", "x" . Pad . " y" . (H-26) . " w" . (W-Pad*2),
    "Vexora v2.7 ready")

MyGui.Show("w" . W . " h" . H)

; ── INIT ─────────────────────────────────────────────────────
LoadConfig()
ApplyTheme(currentTheme)
SaveAndApply()
SetTimer(CheckCS2, 2000)
SetTimer(PollBombLog, 400)
SetTimer(CheckSniperState, 100)

if chkKeyDisplay.Value
    ShowKeyDisplay()

; ================================================================
;  UI HELPER
; ================================================================
DrawCard(x, y, w, h, title, subtitle) {
    MyGui.Add("Text", "x" . x . " y" . y . " w" . w . " h" . h . " Background12121C")
    MyGui.Add("Text", "x" . x . " y" . y . " w3 h" . h . " Background6366F1")
    MyGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
    MyGui.Add("Text", "x" . (x+12) . " y" . (y+8) . " w" . (w-24) . " BackgroundTrans", title)
    MyGui.SetFont("s7 c6B7280", "Segoe UI")
    MyGui.Add("Text", "x" . (x+12) . " y" . (y+24) . " w" . (w-24) . " BackgroundTrans", subtitle)
    MyGui.SetFont("s9 cE5E7EB", "Segoe UI")
}

; ================================================================
;  EVENT HANDLERS
; ================================================================
ToggleAOT(*) {
    MyGui.Opt(chkAOT.Value ? "+AlwaysOnTop" : "-AlwaysOnTop")
}

ThemeChanged(*) {
    ApplyTheme(ddTheme.Text)
}

ToggleKDCheck(*) {
    if chkKeyDisplay.Value
        ShowKeyDisplay()
    else
        HideKeyDisplay()
}

StartBombBtn(*) {
    StartBomb()
}

StopBombBtn(*) {
    StopBomb()
}

BombPosTop(*) {
    SetBombPosition("top")
}

BombPosBL(*) {
    SetBombPosition("bl")
}

BombPosBR(*) {
    SetBombPosition("br")
}

KDPosBL(*) {
    SetKDPosition("bl")
}

KDPosBR(*) {
    SetKDPosition("br")
}

KDPosBC(*) {
    SetKDPosition("bc")
}

KDPresetHandler(hex, *) {
    edKDColor.Value := hex
    SaveConfig()
}

DotPresetHandler(hex, *) {
    edDotColor.Value := hex
    RefreshSniper()
    SaveConfig()
}

RefreshDotEvt(*) {
    RefreshSniper()
    SaveConfig()
}

ResetConfig(*) {
    if FileExist(CONFIG_FILE)
        FileDelete(CONFIG_FILE)
    Reload()
}

; ================================================================
;  POSITION PRESETS
; ================================================================
SetBombPosition(preset) {
    global bombPosX, bombPosY, BombGui
    sw := A_ScreenWidth
    sh := A_ScreenHeight
    if (preset = "top") {
        bombPosX := (sw - 260) / 2
        bombPosY := 60
    } else if (preset = "bl") {
        bombPosX := 30
        bombPosY := sh - 220
    } else if (preset = "br") {
        bombPosX := sw - 290
        bombPosY := sh - 220
    }
    try edBombX.Value := bombPosX
    try edBombY.Value := bombPosY
    IniWrite(bombPosX, CONFIG_FILE, "Bomb", "PosX")
    IniWrite(bombPosY, CONFIG_FILE, "Bomb", "PosY")
    if BombGui && BombGui.Hwnd
        try BombGui.Move(bombPosX, bombPosY)
}

SetKDPosition(preset) {
    global kdPosX, kdPosY, KeyGui
    sw := A_ScreenWidth
    sh := A_ScreenHeight
    if (preset = "bl") {
        kdPosX := 30
        kdPosY := sh - 250
    } else if (preset = "br") {
        kdPosX := sw - 210
        kdPosY := sh - 250
    } else if (preset = "bc") {
        kdPosX := (sw - 180) / 2
        kdPosY := sh - 210
    }
    try edKDX.Value := kdPosX
    try edKDY.Value := kdPosY
    IniWrite(kdPosX, CONFIG_FILE, "KeyDisplay", "PosX")
    IniWrite(kdPosY, CONFIG_FILE, "KeyDisplay", "PosY")
    if KeyGui && KeyGui.Hwnd
        try KeyGui.Move(kdPosX, kdPosY)
}

; ================================================================
;  MAIN CALLBACKS
; ================================================================
ApplyTheme(name) {
    global currentTheme := name
    theme := GetTheme(name)
    try MyGui.BackColor := theme["bg"]
    CheckCS2()
    SaveConfig()
}

CheckCS2(*) {
    interval := ParseInt(edCS2Interval.Value)
    if (interval < 500)
        interval := 2000
    SetTimer(CheckCS2, interval)

    theme := GetTheme()
    if CS2Active() {
        lblCS2.SetFont("s8 c" . theme["good"] . " Bold")
        lblCS2.Value := "● FOCUSED"
    } else if CS2Running() {
        lblCS2.SetFont("s8 c" . theme["warn"] . " Bold")
        lblCS2.Value := "◐ BACKGROUND"
    } else {
        lblCS2.SetFont("s8 c" . theme["bad"] . " Bold")
        lblCS2.Value := "○ NOT FOUND"
    }

    if chkAutoDisable.Value && !CS2Active() {
        global bhopActive, pistolActive, scopeToggled
        bhopActive := false
        pistolActive := false
        scopeToggled := false
        SetTimer(BhopTick, 0)
        SetTimer(PistolTick, 0)
    }
}

SaveAndApply(*) {
    global bhopLimit, pistolCPS, bhopActive, pistolActive, scopeToggled
    global bombPosX, bombPosY, kdPosX, kdPosY

    bhopLimit := ParseInt(edBhop.Value)
    pistolCPS := ParseInt(edPistolCPS.Value)
    if (bhopLimit < 1)
        bhopLimit := 50
    if (pistolCPS < 1)
        pistolCPS := 50

    try {
        bombPosX := ParseInt(edBombX.Value)
        bombPosY := ParseInt(edBombY.Value)
        kdPosX   := ParseInt(edKDX.Value)
        kdPosY   := ParseInt(edKDY.Value)
    }

    bhopActive := false
    pistolActive := false
    scopeToggled := false
    SetTimer(BhopTick, 0)
    SetTimer(PistolTick, 0)

    SetupHotkeys()
    SetupSlotTracking()
    SetupBombKey()
    SetupSnapTap()
    UpdateSnapTapIndicator()

    global autoStrafeEnabled
    autoStrafeEnabled := chkAutoStrafe.Value
    if autoStrafeEnabled {
        rate := ParseInt(edStrafeRate.Value)
        SetTimer(AutoStrafeTick, rate)
    } else {
        SetTimer(AutoStrafeTick, 0)
    }

    SaveConfig()

    if chkKeyDisplay.Value
        ShowKeyDisplay()
    else
        HideKeyDisplay()

    RefreshSniper()

    lblStatus.SetFont("s8 c10B981 Bold")
    lblStatus.Value := "✔ All settings saved & applied"
    SetTimer(ResetStatus, -3000)
}

ResetStatus(*) {
    lblStatus.SetFont("s8 c6B7280")
    lblStatus.Value := "Vexora v2.7 ready"
}

; ================================================================
;  HOTKEY SETUP
; ================================================================
SetupHotkeys() {
    bhopKey := Trim(edKeyBhop.Value)
    if (bhopKey = "")
        bhopKey := "Space"
    pistolKey := Trim(edKeyPistol.Value)
    if (pistolKey = "")
        pistolKey := "LButton"
    scopeKey := Trim(edKeyScope.Value)
    if (scopeKey = "")
        scopeKey := "e"

    if chkBhop.Value {
        HotIfWinActive "ahk_exe " . CS2_EXE
        Hotkey "~$" . bhopKey,         BhopDown, "On"
        Hotkey "~$" . bhopKey . " up", BhopUp,   "On"
        HotIfWinActive
    } else {
        try {
            HotIfWinActive "ahk_exe " . CS2_EXE
            Hotkey "~$" . bhopKey,         "Off"
            Hotkey "~$" . bhopKey . " up", "Off"
            HotIfWinActive
        }
    }

    if chkPistol.Value {
        HotIfWinActive "ahk_exe " . CS2_EXE
        Hotkey "~" . pistolKey,         PistolDown, "On"
        Hotkey "~" . pistolKey . " up", PistolUp,   "On"
        HotIfWinActive
    } else {
        try {
            HotIfWinActive "ahk_exe " . CS2_EXE
            Hotkey "~" . pistolKey,         "Off"
            Hotkey "~" . pistolKey . " up", "Off"
            HotIfWinActive
        }
    }

    if chkScope.Value {
        HotIfWinActive "ahk_exe " . CS2_EXE
        Hotkey "~$" . scopeKey, ScopeToggle, "On"
        HotIfWinActive
    } else {
        try {
            HotIfWinActive "ahk_exe " . CS2_EXE
            Hotkey "~$" . scopeKey, "Off"
            HotIfWinActive
        }
    }
}

SetupBombKey() {
    bombKey := Trim(edBombKey.Value)
    if (bombKey = "")
        bombKey := "F5"
    if chkBombTimer.Value {
        HotIfWinActive "ahk_exe " . CS2_EXE
        Hotkey "~$" . bombKey, ManualBombToggle, "On"
        HotIfWinActive
    } else {
        try {
            HotIfWinActive "ahk_exe " . CS2_EXE
            Hotkey "~$" . bombKey, "Off"
            HotIfWinActive
        }
    }
}

; ================================================================
;  BHOP
; ================================================================
BhopDown(*) {
    global bhopActive
    if !CS2Active() || bhopActive
        return
    bhopActive := true
    SetTimer(BhopTick, BhopDelay())
}

BhopUp(*) {
    global bhopActive
    bhopActive := false
    SetTimer(BhopTick, 0)
}

BhopTick(*) {
    global bhopActive
    if !bhopActive || !CS2Active() {
        SetTimer(BhopTick, 0)
        bhopActive := false
        return
    }
    Send "{Space}"
}

; ================================================================
;  PISTOL
; ================================================================
PistolDown(*) {
    global pistolActive
    if !CS2Active() || pistolActive
        return
    if !IsPistolSlot()
        return
    pistolActive := true
    SetTimer(PistolTick, PistolDelay())
}

PistolUp(*) {
    global pistolActive
    pistolActive := false
    SetTimer(PistolTick, 0)
}

PistolTick(*) {
    global pistolActive
    if !pistolActive || !CS2Active() || !IsPistolSlot() {
        SetTimer(PistolTick, 0)
        pistolActive := false
        return
    }
    Click
}

; ================================================================
;  SCOPE
; ================================================================
ScopeToggle(*) {
    global scopeToggled
    if !CS2Active()
        return
    scopeToggled := !scopeToggled
    if scopeToggled
        SetTimer(ScopeSequence, -1)
}

ScopeSequence(*) {
    global scopeToggled
    if !CS2Active() {
        scopeToggled := false
        return
    }
    ads  := ParseInt(edScopeADS.Value)
    post := ParseInt(edScopePost.Value)
    s1   := Trim(edSlot1.Value)
    s2   := Trim(edSlot2.Value)
    if (ads < 1)
        ads := 5
    if (post < 1)
        post := 64

    Click "Right"
    Sleep ads
    Click
    Sleep post
    Send "{" . s1 . "}"
    Sleep 30
    Send "{" . s2 . "}"
    scopeToggled := false
}

; ================================================================
;  SNAP TAP  (counter-strafe for W/A/S/D)
; ================================================================
ToggleSnapTap(*) {
    global snapTapEnabled
    snapTapEnabled := chkSnapTap.Value
    SetupSnapTap()
    UpdateSnapTapIndicator()
}

UpdateSnapTapIndicator() {
    try {
        if snapTapEnabled {
            snapTapIndicator.Value := "● SNAP TAP: ON"
            snapTapIndicator.SetFont("s9 c10B981 Bold")
        } else {
            snapTapIndicator.Value := "○ SNAP TAP: OFF"
            snapTapIndicator.SetFont("s9 cEF4444 Bold")
        }
    }
}

SetupSnapTap() {
    global snapTapEnabled
    try {
        HotIfWinActive "ahk_exe " . CS2_EXE
        if snapTapEnabled {
            ; W ↔ S
            Hotkey "~w",    SnapW_Dn, "On"
            Hotkey "~w up", SnapW_Up, "On"
            Hotkey "~s",    SnapS_Dn, "On"
            Hotkey "~s up", SnapS_Up, "On"
            ; A ↔ D
            Hotkey "~a",    SnapA_Dn, "On"
            Hotkey "~a up", SnapA_Up, "On"
            Hotkey "~d",    SnapD_Dn, "On"
            Hotkey "~d up", SnapD_Up, "On"
        } else {
            try Hotkey "~w",    "Off"
            try Hotkey "~w up", "Off"
            try Hotkey "~s",    "Off"
            try Hotkey "~s up", "Off"
            try Hotkey "~a",    "Off"
            try Hotkey "~a up", "Off"
            try Hotkey "~d",    "Off"
            try Hotkey "~d up", "Off"
        }
        HotIfWinActive
    }
}

SnapW_Dn(*) {
    global snapTapW, snapTapS
    if snapTapS {
        Send "{s up}"
        snapTapS := false
    }
    snapTapW := true
}
SnapW_Up(*) {
    global snapTapW
    snapTapW := false
}
SnapS_Dn(*) {
    global snapTapS, snapTapW
    if snapTapW {
        Send "{w up}"
        snapTapW := false
    }
    snapTapS := true
}
SnapS_Up(*) {
    global snapTapS
    snapTapS := false
}
SnapA_Dn(*) {
    global snapTapA, snapTapD
    if snapTapD {
        Send "{d up}"
        snapTapD := false
    }
    snapTapA := true
}
SnapA_Up(*) {
    global snapTapA
    snapTapA := false
}
SnapD_Dn(*) {
    global snapTapD, snapTapA
    if snapTapA {
        Send "{a up}"
        snapTapA := false
    }
    snapTapD := true
}
SnapD_Up(*) {
    global snapTapD
    snapTapD := false
}

; F8 — Toggle Snap Tap with notification + indicator update
F8:: {
    global snapTapEnabled
    if !CS2Active()
        return
    snapTapEnabled := !snapTapEnabled
    try chkSnapTap.Value := snapTapEnabled
    SetupSnapTap()
    UpdateSnapTapIndicator()
    msg := snapTapEnabled ? "Snap Tap: ON" : "Snap Tap: OFF"
    clr := snapTapEnabled ? 0x10B981 : 0xEF4444
    TrayTip "Vexora", msg, 1
    ToolTip msg, A_ScreenWidth/2 - 80, A_ScreenHeight - 80
    SetTimer(() => ToolTip(), -1500)
}

; ================================================================
;  AUTO STRAFE
; ================================================================
ToggleAutoStrafe(*) {
    global autoStrafeEnabled
    autoStrafeEnabled := chkAutoStrafe.Value
    if autoStrafeEnabled
        SetTimer(AutoStrafeTick, ParseInt(edStrafeRate.Value))
    else {
        SetTimer(AutoStrafeTick, 0)
        Send "{a up}{d up}"
    }
}

AutoStrafeTick(*) {
    global strafeDir, autoStrafeEnabled
    if !autoStrafeEnabled || !CS2Active() {
        SetTimer(AutoStrafeTick, 0)
        Send "{a up}{d up}"
        return
    }
    ; Only strafe if space held (in air / bunnyhopping)
    if !GetKeyState("Space", "P")
        return
    rate := ParseInt(edStrafeRate.Value)
    if (rate < 5)
        rate := 25
    SetTimer(AutoStrafeTick, rate)
    if (strafeDir = 1) {
        Send "{a up}{d down}"
        strafeDir := -1
    } else {
        Send "{d up}{a down}"
        strafeDir := 1
    }
}

; ================================================================
;  CLEANUP
; ================================================================
ExitCleanup(*) {
    SaveConfig()
    SetTimer(AutoStrafeTick, 0)
    Send "{a up}{d up}{w up}{s up}"
    global BombGui, KeyGui, SniperGui
    if BombGui {
        BombGui.Destroy()
        BombGui := 0
    }
    if KeyGui {
        KeyGui.Destroy()
        KeyGui := 0
    }
    if SniperGui {
        SniperGui.Destroy()
        SniperGui := 0
    }
    ExitApp
}
