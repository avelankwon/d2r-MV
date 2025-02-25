

ReadOtherPlayers(ByRef d2rprocess, startingOffset, ByRef otherPlayers) {
    otherPlayers := []
    SetFormat Integer, D

    found := false
    , baseAddress := d2rprocess.BaseAddress + startingOffset
    , d2rprocess.readRaw(baseAddress, unitTableBuffer, 128*8)
    loop, 128
    {
        ;WriteLogDebug("Attempt " A_Index " with starting offset " startingOffset)
        offset := (8 * (A_Index - 1))
        , playerUnit := NumGet(&unitTableBuffer , offset, "Int64")
        while (playerUnit > 0) { ; keep following the next pointer
            pInventory := playerUnit + 0x90
            , inventory := d2rprocess.read(pInventory, "Int64")
            if (inventory) {
                
                expChar := d2rprocess.read(d2rprocess.BaseAddress + expOffset, "UShort")
                , basecheck := (d2rprocess.read(inventory + 0x30, "UShort")) != 1
                if (expChar) {
                    basecheck := (d2rprocess.read(inventory + 0x70, "UShort")) != 0
                }
                
                if (basecheck) {
                    pAct := playerUnit + 0x20
                    , actAddress := d2rprocess.read(pAct, "Int64")
                    , mapSeedAddress := actAddress + 0x14
                    , mapSeed := d2rprocess.read(mapSeedAddress, "UInt")
                    , pPath := playerUnit + 0x38
                    , pathAddress := d2rprocess.read(pPath, "Int64")
                    , xPos := d2rprocess.read(pathAddress + 0x02, "UShort")
                    , yPos := d2rprocess.read(pathAddress + 0x06, "UShort")
                    , xPosOffset := d2rprocess.read(pathAddress + 0x00, "UShort") 
                    , yPosOffset := d2rprocess.read(pathAddress + 0x04, "UShort")
                    , xPosOffset := xPosOffset / 65536   ; get percentage
                    , yPosOffset := yPosOffset / 65536   ; get percentage
                    , xPos := xPos + xPosOffset
                    , yPos := yPos + yPosOffset
                    , pUnitData := playerUnit + 0x10
                    , playerNameAddress := d2rprocess.read(pUnitData, "Int64")
                    , playerName := d2rprocess.readString(playerNameAddress, length := 0)
                    
                    if (xPos > 0 and yPos > 0) {
                        SetFormat Integer, D
                        otherPlayers.push({ "player": A_Index, "playerName": playerName, "x": xPos, "y": yPos})
                    }
                }
            }
            playerUnit := d2rprocess.read(playerUnit + 0x150, "Int64")  ; get next player
        }
    }
    SetFormat Integer, D

}