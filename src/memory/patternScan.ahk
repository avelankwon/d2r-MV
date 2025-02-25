

PatternScan(ByRef d2r, ByRef offsets) {
    SetFormat, Integer, Hex
    ; unit table
    pattern := d2r.hexStringToPattern("48 8D ?? ?? ?? ?? ?? 8B D1")
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    offsetBuffer := d2r.read(patternAddress + 3, "Int")
    playerOffset := ((patternAddress - d2r.BaseAddress) + 7 + offsetBuffer)
    offsets["playerOffset"] := playerOffset
    WriteLog("Scanned and found unitTable offset: " playerOffset)
    
    ; ui
    pattern := d2r.hexStringToPattern("40 84 ed 0f 94 05")
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    offsetBuffer := d2r.read(patternAddress + 6, "Int")
    uiOffset := ((patternAddress - d2r.BaseAddress) + 10 + offsetBuffer)
    offsets["uiOffset"] := uiOffset
    WriteLog("Scanned and found UI offset: " uiOffset)

    ; expansion
    pattern := d2r.hexStringToPattern("C7 05 ?? ?? ?? ?? ?? ?? ?? ?? 48 85 C0 0F 84 ?? ?? ?? ?? 83 78 5C ?? 0F 84 ?? ?? ?? ?? 33 D2 41")   ;unit table offset
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    offsetBuffer := d2r.read(patternAddress - 4, "Int")
    expOffset := ((patternAddress - d2r.BaseAddress) + offsetBuffer)
    offsets["expOffset"] := expOffset
    WriteLog("Scanned and found expansion offset: " expOffset)

    ; game data (IP and name) 
    ; pattern := d2r.hexStringToPattern("48 83 C4 28 C3 1A DF")
    ; patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    ; offsetBuffer := d2r.read(patternAddress - 0x44, "Int")
    ; gameDataOffset := ((patternAddress - d2r.BaseAddress) + 0x145 + offsetBuffer)
    gameDataOffset := 0x29B7A70
    offsets["gameDataOffset"] := gameDataOffset
    WriteLog("Scanned and found game data offset: " gameDataOffset)

    ; menu visibility    
    pattern := d2r.hexStringToPattern("8B 05 ?? ?? ?? ?? 89 44 24 20 74 07") 
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    offsetBuffer := d2r.read(patternAddress + 2, "Int")
    menuOffset := ((patternAddress - d2r.BaseAddress) + 6 + offsetBuffer)
    offsets["menuOffset"] := menuOffset
    WriteLog("Scanned and found menu offset: " menuOffset)

    ; last hover object
    pattern := d2r.hexStringToPattern("C6 84 C2 ?? ?? ?? ?? ?? 48 8B 74 24 ??") 
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    hoverOffset := d2r.read(patternAddress + 3, "Int") - 1
    offsets["hoverOffset"] := hoverOffset
    WriteLog("Scanned and found hover offset: " hoverOffset)

    ; roster
    pattern := d2r.hexStringToPattern("02 45 33 D2 4D 8B") 
    patternAddress := d2r.modulePatternScan("D2R.exe", , pattern*)
    offsetBuffer := d2r.read(patternAddress - 3, "Int")
    rosterOffset := ((patternAddress - d2r.BaseAddress) + 1 + offsetBuffer)
    offsets["rosterOffset"] := rosterOffset
    WriteLog("Scanned and found roster offset: " rosterOffset)
    
    SetFormat, Integer, D
}