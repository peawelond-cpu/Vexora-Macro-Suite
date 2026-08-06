; ================================================================
;  VEXORA — CS2 Macro Suite v2.2
;  AutoHotkey v2.0
;  Features: Bhop, Auto Pistol, Fast Scope,
;            Auto Bomb Timer, Key Display Overlay
; ================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

CS2_EXE     := "cs2.exe"
CONFIG_FILE := A_ScriptDir . "\vexora_config.ini"

; ── Global State ─────────────────────────────────────────────
global bhopActive     := false
global pistolActive   := false
global scopeToggled   := false
global bhopLimit      := 50
global pistolCPS      := 50
global currentTheme   := "Dark"
global currentSlot    := 0
global BOMB_TIME      := 40

; Bomb timer
global bombPlanted    := false
global bombStartTick  := 0
global lastLogSize    := 0
global logFilePath    := ""

; ── Utility ──────────────────────────────────────────────────
BhopDelay()   => Max(1, Round(1000 / bhopLimit))
PistolDelay() => Max(1, Round(1000 / pistolCPS))
CS2Active()   => WinActive("ahk_exe " . CS2_EXE)
CS2Running()  => ProcessExist(CS2_EXE) ? true : false

ParseInt(val) {
    c := RegExReplace(String(val), "[^\d]", "")
    return (c = "") ? 0 : Integer(c)
}

; ================================================================
;  THEMES
; ================================================================
Themes := Map(
    "Dark",     Map("bg","0C0C14","panel","11111E","accent","5E6BFF",
                    "text","D8D8F0","dim","666688","good","3AE87A",
                    "bad","FF4466","warn","FFB844","divider","1E1E33",
                    "edit","14142A","btnBg","5E6BFF","header","0F0F1A"),
    "Midnight", Map("bg","0A1225","panel","0E1830","accent","3FA9F5",
                    "text","C8DDEF","dim","5A80A5","good","3AE87A",
                    "bad","FF5566","warn","FFB844","divider","1A3050",
                    "edit","0C1828","btnBg","3FA9F5","header","0C1628"),
    "Purple",   Map("bg","14081E","panel","1A0E28","accent","A855F7",
                    "text","DACCF0","dim","7A68AA","good","3AE87A",
                    "bad","FF5566","warn","FFB855","divider","2A1A40",
                    "edit","180E28","btnBg","A855F7","header","180C22"),
    "Emerald",  Map("bg","081410","panel","0E1E18","accent","34D399",
                    "text","C8F0D8","dim","5A9F78","good","3AE87A",
                    "bad","FF5566","warn","FFB844","divider","1A3F2A",
                    "edit","0C2018","btnBg","34D399","header","0C1812"),
    "Crimson",  Map("bg","140A0C","panel","1E1012","accent","FF3355",
                    "text","F0D0D5","dim","AA6670","good","3AE87A",
                    "bad","FF5566","warn","FFB844","divider","3F1A22",
                    "edit","201015","btnBg","FF3355","header","180C10"),
    "Frost",    Map("bg","EEF2F7","panel","E4E8EE","accent","3388DD",
                    "text","2A3A4A","dim","778899","good","22AA55",
                    "bad","DD3344","warn","DD8800","divider","CCD0D8",
                    "edit","FFFFFF","btnBg","3388DD","header","E0E4EA")
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
    IniWrite(currentTheme,         f, "General", "Theme")
    IniWrite(chkAOT.Value,         f, "General", "AlwaysOnTop")
    IniWrite(edCS2Interval.Value,  f, "General", "CS2Interval")
    IniWrite(chkAutoDisable.Value, f, "General", "AutoDisable")

    IniWrite(chkBhop.Value,        f, "Macros", "BhopOn")
    IniWrite(edBhop.Value,         f, "Macros", "BhopRate")
    IniWrite(chkPistol.Value,      f, "Macros", "PistolOn")
    IniWrite(edPistolCPS.Value,    f, "Macros", "PistolCPS")
    IniWrite(chkScope.Value,       f, "Macros", "ScopeOn")
    IniWrite(edScopeADS.Value,     f, "Macros", "ScopeADS")
    IniWrite(edScopePost.Value,    f, "Macros", "ScopePost")
    IniWrite(edSlot1.Value,        f, "Macros", "Slot1")
    IniWrite(edSlot2.Value,        f, "Macros", "Slot2")

    IniWrite(edKeyBhop.Value,      f, "Keys", "Bhop")
    IniWrite(edKeyPistol.Value,    f, "Keys", "Pistol")
    IniWrite(edKeyScope.Value,     f, "Keys", "Scope")

    IniWrite(chkBombTimer.Value,   f, "Bomb", "Enabled")
    IniWrite(chkBombAuto.Value,    f, "Bomb", "AutoMode")
    IniWrite(edBombDur.Value,      f, "Bomb", "Duration")
    IniWrite(edBombKey.Value,      f, "Bomb", "ManualKey")
    IniWrite(edBombOpacity.Value,  f, "Bomb", "Opacity")
    IniWrite(edBombColor.Value,    f, "Bomb", "Color")

    IniWrite(chkKeyDisplay.Value,  f, "KeyDisplay", "Enabled")
    IniWrite(edKDOpacity.Value,    f, "KeyDisplay", "Opacity")
    IniWrite(edKDColor.Value,      f, "KeyDisplay", "Color")
}

LoadConfig() {
    global currentTheme
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
    try edBombOpacity.Value := IniRead(f, "Bomb", "Opacity", "230")
    try edBombColor.Value   := IniRead(f, "Bomb", "Color", "34D399")

    try chkKeyDisplay.Value := IniRead(f, "KeyDisplay", "Enabled", 0)
    try edKDOpacity.Value   := IniRead(f, "KeyDisplay", "Opacity", "200")
    try edKDColor.Value     := IniRead(f, "KeyDisplay", "Color", "FF3366")

    for i, name in ["Dark", "Midnight", "Purple", "Emerald", "Crimson", "Frost"] {
        if (name = currentTheme) {
            ddTheme.Choose(i)
            break
        }
    }
    if chkAOT.Value
        MyGui.Opt("+AlwaysOnTop")
}

; ================================================================
;  BOMB TIMER OVERLAY (Circular style)
; ================================================================
global BombGui      := 0
global bombIconCtrl := 0
global bombTimeCtrl := 0
global bombRingCtrl := 0

CreateBombGui() {
    global BombGui, bombIconCtrl, bombTimeCtrl, bombRingCtrl

    userColor := Trim(edBombColor.Value)
    if (userColor = "") userColor := "34D399"

    BombGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    BombGui.BackColor := "1a1410"
    BombGui.MarginX := 0
    BombGui.MarginY := 0

    ; C4 icon side
    BombGui.SetFont("s24 cFFFFFF Bold", "Segoe UI")
    bombIconCtrl := BombGui.Add("Text", "x8 y15 w60 h50 Center BackgroundTrans", "💣")

    BombGui.SetFont("s10 cFFFFFF Bold", "Consolas")
    BombGui.Add("Text", "x8 y58 w60 h16 Center BackgroundTrans", "C4")

    ; Divider
    BombGui.Add("Text", "x76 y10 w1 h60 Background444444", "")

    ; Ring background (drawn via Progress)
    bombRingCtrl := BombGui.Add("Progress",
        "x88 y16 w56 h56 c" . userColor . " Background2a2420 Range0-1000 -Smooth", 1000)

    ; Time text
    BombGui.SetFont("s16 cFFFFFF Bold", "Consolas")
    bombTimeCtrl := BombGui.Add("Text", "x82 y30 w68 h28 Center BackgroundTrans", "40.0")

    ; Make draggable
    for ctrl in [bombIconCtrl, bombTimeCtrl] {
        ctrl.OnEvent("Click",
            (*) => PostMessage(0xA1, 2, 0, , "ahk_id " . BombGui.Hwnd))
    }

    BombGui.OnEvent("ContextMenu", (*) => HideBombTimer())
}

ShowBombTimer() {
    global BombGui
    if !chkBombTimer.Value
        return
    if !BombGui
        CreateBombGui()

    opacity := ParseInt(edBombOpacity.Value)
    opacity := Max(50, Min(255, opacity))

    userColor := Trim(edBombColor.Value)
    if (userColor = "") userColor := "34D399"

    try bombRingCtrl.Opt("+c" . userColor)
    bombRingCtrl.Value := 1000
    bombTimeCtrl.Value := Format("{:.1f}", BOMB_TIME)
    bombTimeCtrl.SetFont("s16 cFFFFFF Bold")

    ; Position: bottom-left
    posX := 20
    posY := A_ScreenHeight - 180

    WinSetTransparent(opacity, BombGui)
    BombGui.Show("x" . posX . " y" . posY . " w158 h84 NoActivate")
}

HideBombTimer() {
    global BombGui
    if BombGui
        BombGui.Hide()
}

UpdateBombTimer(*) {
    global bombPlanted, bombStartTick, BOMB_TIME

    if !bombPlanted {
        SetTimer UpdateBombTimer, 0
        HideBombTimer()
        return
    }

    elapsed   := (A_TickCount - bombStartTick) / 1000
    remaining := BOMB_TIME - elapsed

    if (remaining <= 0) {
        bombPlanted := false
        SetTimer UpdateBombTimer, 0
        bombTimeCtrl.Value := "0.0"
        bombTimeCtrl.SetFont("s16 cFF4466 Bold")
        bombRingCtrl.Value := 0
        SetTimer HideBombTimer, -2500
        return
    }

    pct := Round((remaining / BOMB_TIME) * 1000)
    bombRingCtrl.Value := pct
    bombTimeCtrl.Value := Format("{:.1f}", remaining)

    ; Color changes
    if (remaining <= 5) {
        bombTimeCtrl.SetFont("s16 cFF4466 Bold")
        try bombRingCtrl.Opt("+cFF4466")
    } else if (remaining <= 15) {
        bombTimeCtrl.SetFont("s16 cFFB844 Bold")
        try bombRingCtrl.Opt("+cFFB844")
    } else {
        bombTimeCtrl.SetFont("s16 cFFFFFF Bold")
        userColor := Trim(edBombColor.Value)
        if (userColor = "") userColor := "34D399"
        try bombRingCtrl.Opt("+c" . userColor)
    }
}

StartBomb(*) {
    global bombPlanted, bombStartTick, BOMB_TIME

    BOMB_TIME := ParseInt(edBombDur.Value)
    if (BOMB_TIME < 5) BOMB_TIME := 40

    bombPlanted   := true
    bombStartTick := A_TickCount
    ShowBombTimer()
    SetTimer UpdateBombTimer, 50
}

StopBomb(*) {
    global bombPlanted
    bombPlanted := false
    SetTimer UpdateBombTimer, 0
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
;  AUTO BOMB DETECTION (console.log parsing)
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

    if !chkBombAuto.Value
        return
    if !chkBombTimer.Value
        return
    if !CS2Running()
        return

    if (logFilePath = "" || !FileExist(logFilePath))
        if !FindLogFile()
            return

    try {
        fileSize := FileGetSize(logFilePath)

        ; File was reset (game restart)
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

        ; Detect bomb plant
        if (InStr(chunk, "planted the bomb") || InStr(chunk, "Planted_At")
            || InStr(chunk, "bomb_planted")) {
            if !bombPlanted
                StartBomb()
        }

        ; Detect bomb defuse / explode / round end
        if (InStr(chunk, "Defused_At") || InStr(chunk, "bomb_defused")
            || InStr(chunk, "defused the bomb") || InStr(chunk, "bomb_exploded")
            || InStr(chunk, "round_end") || InStr(chunk, "cs_win_panel_round")) {
            if bombPlanted
                StopBomb()
        }
    }
}

; ================================================================
;  KEY DISPLAY OVERLAY (WASD + LMB/RMB like screenshot)
; ================================================================
global KeyGui := 0
global keyCtrls := Map()
global keyStates := Map(
    "W", false, "A", false, "S", false, "D", false,
    "LMB", false, "RMB", false
)

CreateKeyDisplay() {
    global KeyGui, keyCtrls

    userColor := Trim(edKDColor.Value)
    if (userColor = "") userColor := "FF3366"

    KeyGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    KeyGui.BackColor := "1a1410"
    KeyGui.MarginX := 0
    KeyGui.MarginY := 0
    KeyGui.SetFont("s11 cFFFFFF Bold", "Segoe UI")

    ; W (top center)
    keyCtrls["W"] := KeyGui.Add("Text", "x54 y8 w40 h30 Center Background2a2420 Border", "W")
    ; A S D (middle row)
    keyCtrls["A"] := KeyGui.Add("Text", "x8 y42 w40 h30 Center Background2a2420 Border", "A")
    keyCtrls["S"] := KeyGui.Add("Text", "x54 y42 w40 h30 Center Background2a2420 Border", "S")
    keyCtrls["D"] := KeyGui.Add("Text", "x100 y42 w40 h30 Center Background2a2420 Border", "D")
    ; LMB RMB (bottom)
    KeyGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    keyCtrls["LMB"] := KeyGui.Add("Text", "x8 y76 w62 h30 Center Background2a2420 Border", "LMB")
    keyCtrls["RMB"] := KeyGui.Add("Text", "x78 y76 w62 h30 Center Background2a2420 Border", "RMB")

    ; Drag by any key
    for name, ctrl in keyCtrls
        ctrl.OnEvent("Click", (*) => PostMessage(0xA1, 2, 0, , "ahk_id " . KeyGui.Hwnd))

    KeyGui.OnEvent("ContextMenu", (*) => (chkKeyDisplay.Value := 0, HideKeyDisplay()))
}

ShowKeyDisplay() {
    global KeyGui
    if !KeyGui
        CreateKeyDisplay()

    opacity := ParseInt(edKDOpacity.Value)
    opacity := Max(50, Min(255, opacity))

    posX := 20
    posY := A_ScreenHeight - 300

    WinSetTransparent(opacity, KeyGui)
    KeyGui.Show("x" . posX . " y" . posY . " w148 h114 NoActivate")

    SetTimer UpdateKeyDisplay, 30
}

HideKeyDisplay() {
    global KeyGui
    SetTimer UpdateKeyDisplay, 0
    if KeyGui
        KeyGui.Hide()
}

UpdateKeyDisplay(*) {
    global keyCtrls, keyStates

    if !chkKeyDisplay.Value {
        HideKeyDisplay()
        return
    }

    userColor := Trim(edKDColor.Value)
    if (userColor = "") userColor := "FF3366"

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
                if pressed
                    keyCtrls[name].Opt("+Background" . userColor)
                else
                    keyCtrls[name].Opt("+Background2a2420")
                keyCtrls[name].Redraw()
            }
        }
    }
}

; ================================================================
;  PISTOL SLOT DETECTION
; ================================================================
TrackSlot(n) => (currentSlot := n)

SetupSlotTracking() {
    HotIfWinActive "ahk_exe " . CS2_EXE
    Hotkey "~1", (*) => TrackSlot(1), "On"
    Hotkey "~2", (*) => TrackSlot(2), "On"
    Hotkey "~3", (*) => TrackSlot(3), "On"
    Hotkey "~4", (*) => TrackSlot(4), "On"
    Hotkey "~5", (*) => TrackSlot(5), "On"
    HotIfWinActive
}

IsPistolSlot() => (currentSlot = 2)

; ================================================================
;  MAIN GUI
; ================================================================
W := 480
H := 700
Pad := 24

MyGui := Gui("+Resize -MaximizeBox", "Vexora v2.2")
MyGui.BackColor := "0C0C14"
MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
MyGui.OnEvent("Close", (*) => ExitCleanup())

; ── Header ───────────────────────────────────────────────────
MyGui.Add("Text", "x0 y0 w" . W . " h70 Background0F0F1A")

MyGui.SetFont("s18 cFFFFFF Bold", "Segoe UI")
titleCtrl := MyGui.Add("Text", "x" . Pad . " y14 w200 h30 BackgroundTrans", "VEXORA")

MyGui.SetFont("s8 c7070CC", "Segoe UI")
subtitleCtrl := MyGui.Add("Text", "x" . Pad . " y42 BackgroundTrans", "CS2 MACRO SUITE")

MyGui.SetFont("s7 c444488", "Segoe UI")
versionCtrl := MyGui.Add("Text", "x" . (W-80) . " y16 w60 Right BackgroundTrans", "v2.2")

MyGui.SetFont("s8 c999999", "Segoe UI")
MyGui.Add("Text", "x" . (W-200) . " y44 w40 BackgroundTrans", "CS2:")
lblCS2 := MyGui.Add("Text", "x" . (W-158) . " y44 w150 BackgroundTrans", "...")

; ── Tabs ─────────────────────────────────────────────────────
tabs := MyGui.Add("Tab3", "x0 y70 w" . W . " h580 Choose1",
    ["  ⌨ Macros  ", "  💣 Bomb  ", "  ⌨ Keys  ", "  ⚙ Settings  "])

; ================================================================
;  TAB 1 — MACROS
; ================================================================
tabs.UseTab(1)
LY := 105

; BHOP
MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "BHOP")
MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x80 y" . (LY+2), "— hold to bunny hop")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkBhop := MyGui.Add("CheckBox", "x" . Pad . " y" . LY . " w200", "  Enable")
chkBhop.Value := 1
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Rate (jumps/s)")
edBhop := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "50")
MyGui.Add("UpDown", "Range1-200", 50)
LY += 34

; PISTOL
MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "AUTO PISTOL")
MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x140 y" . (LY+2), "— pistol slot only (press 2)")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkPistol := MyGui.Add("CheckBox", "x" . Pad . " y" . LY . " w200", "  Enable")
chkPistol.Value := 1
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "CPS (clicks/s)")
edPistolCPS := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "50")
MyGui.Add("UpDown", "Range1-100", 50)
LY += 34

; SCOPE
MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "FAST SCOPE")
MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x130 y" . (LY+2), "— quick scope + swap")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkScope := MyGui.Add("CheckBox", "x" . Pad . " y" . LY . " w200", "  Enable")
chkScope.Value := 1
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "ADS → fire (ms)")
edScopeADS := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "5")
MyGui.Add("UpDown", "Range1-500", 5)
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Post-fire (ms)")
edScopePost := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "64")
MyGui.Add("UpDown", "Range1-500", 64)
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Swap slot")
edSlot1 := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "3")
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Return slot")
edSlot2 := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "1")
LY += 34

MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10
btnApply := MyGui.Add("Button", "x" . Pad . " y" . LY . " w160 h34", "✔  Apply")
btnApply.OnEvent("Click", SaveAndApply)

; ================================================================
;  TAB 2 — BOMB TIMER
; ================================================================
tabs.UseTab(2)
LY := 105

MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "BOMB TIMER")
MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x140 y" . (LY+2), "— auto & manual mode")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkBombTimer := MyGui.Add("CheckBox", "x" . Pad . " y" . LY, "  Enable bomb timer overlay")
chkBombTimer.Value := 1
LY += 26

chkBombAuto := MyGui.Add("CheckBox", "x" . Pad . " y" . LY, "  Auto-start (via console.log)")
chkBombAuto.Value := 1
LY += 30

MyGui.Add("Text", "x" . Pad . " y" . LY, "Duration (sec)")
edBombDur := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "40")
MyGui.Add("UpDown", "Range5-90", 40)
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Opacity (50-255)")
edBombOpacity := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "230")
MyGui.Add("UpDown", "Range50-255", 230)
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Ring color (hex)")
edBombColor := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "34D399")
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Manual key")
edBombKey := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "F5")
LY += 32

MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2),
    "AUTO MODE: enable 'con_logfile 1' in CS2 console`n"
    . "MANUAL: press hotkey to start/stop timer`n"
    . "Drag overlay with mouse, right-click to hide")
LY += 68

btnTestBomb := MyGui.Add("Button", "x" . Pad . " y" . LY . " w160 h34", "🧪  Test Overlay")
btnTestBomb.OnEvent("Click", (*) => StartBomb())

btnStopBomb := MyGui.Add("Button", "x200 y" . LY . " w120 h34", "⏹ Stop")
btnStopBomb.OnEvent("Click", (*) => StopBomb())

; ================================================================
;  TAB 3 — KEY DISPLAY
; ================================================================
tabs.UseTab(3)
LY := 105

MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "KEY DISPLAY")
MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x140 y" . (LY+2), "— WASD + mouse overlay")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkKeyDisplay := MyGui.Add("CheckBox", "x" . Pad . " y" . LY, "  Enable key display overlay")
chkKeyDisplay.Value := 0
chkKeyDisplay.OnEvent("Click", (*) => (chkKeyDisplay.Value ? ShowKeyDisplay() : HideKeyDisplay()))
LY += 30

MyGui.Add("Text", "x" . Pad . " y" . LY, "Opacity (50-255)")
edKDOpacity := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "200")
MyGui.Add("UpDown", "Range50-255", 200)
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Active color (hex)")
edKDColor := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "FF3366")
LY += 32

MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s8 c666688", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2),
    "Shows WASD + LMB + RMB visually`n"
    . "Keys light up when pressed`n"
    . "Drag with mouse, right-click to hide`n`n"
    . "Color examples:`n"
    . "  FF3366 = pink/red  |  34D399 = green`n"
    . "  5E6BFF = blue      |  FFB844 = orange")

; ================================================================
;  TAB 4 — SETTINGS
; ================================================================
tabs.UseTab(4)
LY := 105

MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "GENERAL")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
chkAOT := MyGui.Add("CheckBox", "x" . Pad . " y" . LY, "  Always on top")
chkAOT.OnEvent("Click", (*) => MyGui.Opt(chkAOT.Value ? "+AlwaysOnTop" : "-AlwaysOnTop"))
LY += 26

chkAutoDisable := MyGui.Add("CheckBox", "x" . Pad . " y" . LY, "  Pause when CS2 not active")
chkAutoDisable.Value := 1
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "CS2 check (ms)")
edCS2Interval := MyGui.Add("Edit", "x320 y" . (LY-2) . " w70 h22 Center Background14142A", "2000")
MyGui.Add("UpDown", "Range500-10000", 2000)
LY += 34

; THEME
MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "THEME")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "Color scheme")
ddTheme := MyGui.Add("DropDownList", "x320 y" . (LY-2) . " w130 Choose1",
    ["Dark", "Midnight", "Purple", "Emerald", "Crimson", "Frost"])
ddTheme.OnEvent("Change", (*) => ApplyTheme(ddTheme.Text))
LY += 34

; HOTKEYS
MyGui.SetFont("s10 c5E6BFF Bold", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "HOTKEYS")
LY += 22
MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10

MyGui.SetFont("s9 cD8D8F0", "Segoe UI")
MyGui.Add("Text", "x" . Pad . " y" . LY, "Bhop key")
edKeyBhop := MyGui.Add("Edit", "x320 y" . (LY-2) . " w130 h22 Center Background14142A", "Space")
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Pistol key")
edKeyPistol := MyGui.Add("Edit", "x320 y" . (LY-2) . " w130 h22 Center Background14142A", "LButton")
LY += 26

MyGui.Add("Text", "x" . Pad . " y" . LY, "Scope key")
edKeyScope := MyGui.Add("Edit", "x320 y" . (LY-2) . " w130 h22 Center Background14142A", "e")
LY += 40

MyGui.Add("Text", "x" . Pad . " y" . LY . " w" . (W-Pad*2) . " h1 Background1E1E33")
LY += 10
btnSave := MyGui.Add("Button", "x" . Pad . " y" . LY . " w160 h34", "💾  Save & Apply")
btnSave.OnEvent("Click", SaveAndApply)

btnReset := MyGui.Add("Button", "x200 y" . LY . " w100 h34", "Reset")
btnReset.OnEvent("Click", (*) => (FileExist(CONFIG_FILE) && FileDelete(CONFIG_FILE), Reload()))

tabs.UseTab(0)

; ── Footer ───────────────────────────────────────────────────
MyGui.SetFont("s7 c444466", "Segoe UI")
lblStatus := MyGui.Add("Text", "x" . Pad . " y" . (H-26) . " w" . (W-Pad*2),
    "Vexora v2.2 ready — press Apply to activate")

MyGui.Show("w" . W . " h" . H)

; ── INIT ─────────────────────────────────────────────────────
LoadConfig()
ApplyTheme(currentTheme)
SaveAndApply()
SetTimer CheckCS2, 2000
SetTimer PollBombLog, 400

if chkKeyDisplay.Value
    ShowKeyDisplay()

; ================================================================
;  CALLBACKS
; ================================================================
ApplyTheme(name) {
    global currentTheme := name
    theme := GetTheme(name)
    try {
        MyGui.BackColor := theme["bg"]
        titleCtrl.SetFont("s18 cFFFFFF Bold")
    }
    CheckCS2()
}

CheckCS2(*) {
    interval := ParseInt(edCS2Interval.Value)
    if (interval < 500) interval := 2000
    SetTimer CheckCS2, interval

    theme := GetTheme()
    if CS2Running() {
        lblCS2.SetFont("s8 c" . theme["good"])
        lblCS2.Value := "● RUNNING"
    } else {
        lblCS2.SetFont("s8 c" . theme["bad"])
        lblCS2.Value := "○ NOT FOUND"
        if chkAutoDisable.Value {
            global bhopActive, pistolActive, scopeToggled
            bhopActive := pistolActive := scopeToggled := false
            SetTimer BhopTick, 0
            SetTimer PistolTick, 0
        }
    }
}

SaveAndApply(*) {
    global bhopLimit, pistolCPS, bhopActive, pistolActive, scopeToggled

    bhopLimit := ParseInt(edBhop.Value)
    pistolCPS := ParseInt(edPistolCPS.Value)
    if (bhopLimit < 1) bhopLimit := 50
    if (pistolCPS < 1) pistolCPS := 50

    bhopActive := pistolActive := scopeToggled := false
    SetTimer BhopTick, 0
    SetTimer PistolTick, 0

    SetupHotkeys()
    SetupSlotTracking()
    SetupBombKey()
    SaveConfig()

    if chkKeyDisplay.Value
        ShowKeyDisplay()
    else
        HideKeyDisplay()

    lblStatus.Value := "✔ Applied and saved"
}

; ================================================================
;  HOTKEY SETUP
; ================================================================
SetupHotkeys() {
    bhopKey   := Trim(edKeyBhop.Value)   ? Trim(edKeyBhop.Value)   : "Space"
    pistolKey := Trim(edKeyPistol.Value) ? Trim(edKeyPistol.Value) : "LButton"
    scopeKey  := Trim(edKeyScope.Value)  ? Trim(edKeyScope.Value)  : "e"

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
    bombKey := Trim(edBombKey.Value) ? Trim(edBombKey.Value) : "F5"

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
    SetTimer BhopTick, BhopDelay()
}

BhopUp(*) {
    global bhopActive
    bhopActive := false
    SetTimer BhopTick, 0
}

BhopTick(*) {
    global bhopActive
    if !bhopActive || !CS2Active() {
        SetTimer BhopTick, 0
        bhopActive := false
        return
    }
    Send "{Space}"
}

; ================================================================
;  PISTOL (pistol slot only, no delay)
; ================================================================
PistolDown(*) {
    global pistolActive
    if !CS2Active() || pistolActive
        return
    if !IsPistolSlot()
        return
    pistolActive := true
    SetTimer PistolTick, PistolDelay()
}

PistolUp(*) {
    global pistolActive
    pistolActive := false
    SetTimer PistolTick, 0
}

PistolTick(*) {
    global pistolActive
    if !pistolActive || !CS2Active() || !IsPistolSlot() {
        SetTimer PistolTick, 0
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
        SetTimer ScopeSequence, -1
}

ScopeSequence(*) {
    global scopeToggled
    if !CS2Active() {
        scopeToggled := false
        return
    }
    ads   := ParseInt(edScopeADS.Value)
    post  := ParseInt(edScopePost.Value)
    s1    := Trim(edSlot1.Value)
    s2    := Trim(edSlot2.Value)
    if (ads < 1)  ads := 5
    if (post < 1) post := 64

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
;  CLEANUP
; ================================================================
ExitCleanup() {
    SaveConfig()
    global BombGui, KeyGui
    if BombGui {
        BombGui.Destroy()
        BombGui := 0
    }
    if KeyGui {
        KeyGui.Destroy()
        KeyGui := 0
    }
    ExitApp
}