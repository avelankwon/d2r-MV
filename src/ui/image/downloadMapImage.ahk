#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include %A_ScriptDir%\include\logging.ahk

downloadMapImage(settings, gameMemoryData, ByRef mapData, tries) {
    static serverisv10
    errormsg1 := localizedStrings["errormsg1"]
    errormsg2 := localizedStrings["errormsg2"]
    errormsg3 := localizedStrings["errormsg3"]
    errormsg4 := localizedStrings["errormsg4"]
    errormsg5 := localizedStrings["errormsg5"]
    errormsg6 := localizedStrings["errormsg6"]
    errormsg7 := localizedStrings["errormsg7"]
    errormsg8 := localizedStrings["errormsg8"]
    errormsg9 := localizedStrings["errormsg9"]

    baseUrl:= settings["baseUrl"]
    t := settings["wallThickness"] + 0.0
    if (t > 5)
        t := 5
    if (t < 1)
        t := 1
    
    imageUrl := baseUrl . "/v1/map/" . gameMemoryData["mapSeed"] . "/" . gameMemoryData["difficulty"] . "/" . gameMemoryData["levelNo"] . "/image?wallthickness=" . t
    sFile := A_Temp . "\" . gameMemoryData["mapSeed"] . "_" . gameMemoryData["difficulty"] . "_" . gameMemoryData["levelNo"]
    sFileTxt := A_Temp . "\" . gameMemoryData["mapSeed"] . "_" . gameMemoryData["difficulty"] . "_" . gameMemoryData["levelNo"]
    imageUrl := imageUrl . "&rotate=true&showTextLabels=false"
    imageUrl := imageUrl . "&padding=" . settings["padding"]
    if (settings["edges"]) {
        imageUrl := imageUrl . "&edge=true"
    }
    if (settings["centerMode"]) {
        imageUrl := imageUrl . "&serverScale=" . settings["serverScale"]
        sFile .= "_Center"
        sFileTxt .= "_Center"
    }
    
    sFile .= ".png"
    sFileTxt .= ".txt"

    levelNo := gameMemoryData["levelNo"]
    IniRead, levelScale, mapconfig.ini, %levelNo%, scale, 1.0
    IniRead, levelxmargin, mapconfig.ini, %levelNo%, x, 0
    IniRead, levelymargin, mapconfig.ini, %levelNo%, y, 0
    ;WriteLog("Read levelScale " levelScale " " levelxmargin " " levelymargin " from file")

    if (not FileExist(sFile) or not FileExist(sFileTxt)) {
        ; if either file is missing, do a fresh download
        FileDelete, %sFile%
        FileDelete, %sFileTxt%
        tries := 0
        Loop, 5
        {
            tries++
            try {
                whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
                whr.SetTimeouts("45000", "45000", "45000", "45000")
                whr.Open("GET", imageUrl, true)
                whr.Send()
                whr.WaitForResponse()

                fileContents := whr.ResponseBody
                respHeaders := whr.GetAllResponseHeaders
                vStream := whr.ResponseStream

                if (ComObjType(vStream) = 0xD) {      ;VT_UNKNOWN = 0xD
                    pIStream := ComObjQuery(vStream, "{0000000c-0000-0000-C000-000000000046}")	;defined in ObjIdl.h

                    oFile := FileOpen( sFile, "w")
                    Loop {	
                        VarSetCapacity(Buffer, 8192)
                        hResult := DllCall(NumGet(NumGet(pIStream + 0) + 3 * A_PtrSize)	; IStream::Read 
                            , "ptr", pIStream	
                            , "ptr", &Buffer			;pv [out] A pointer to the buffer which the stream data is read into.
                            , "uint", 8192			;cb [in] The number of bytes of data to read from the stream object.
                            , "ptr*", cbRead)		;pcbRead [out] A pointer to a ULONG variable that receives the actual number of bytes read from the stream object. 
                        oFile.RawWrite(&Buffer, cbRead)
                    } Until (cbRead = 0)
                    ObjRelease(pIStream)
                    oFile.Close()
                }
                if (respHeaders)
                    break
            } catch e {
                errMsg := e.message
                errMsg := StrReplace(errMsg, "`nSource:`t`tWinHttp.WinHttpRequest`nDescription:`t", "")
                errMsg := StrReplace(errMsg, "`r`n`nHelpFile:`t`t(null)`nHelpContext:`t0", "")
                WriteLog("ERROR: " errMsg)
                Loop, Parse, respHeaders, `n
                {
                    WriteLog("Response Header: " A_LoopField)
                }
                if (FileExist(sFile)) {
                    WriteLog("Map image exists in cache " sFile)
                }
                if (Instr(errMsg, "The operation timed out")) {
                    WriteLog("ERROR: Timeout downloading image from " imageUrl)
                    WriteLog("The mapserver likely isn't running for some reason")
                }
                if (A_Index == 5) {
                    WriteLog("ERROR: Could not load map even after retrying 5 times " errMsg)
                    Msgbox, 48, d2r-mapview %version%, %errormsg4% %baseUrl%.`n%errormsg5%`n%errormsg6%`n`n%errMsg%`n%errormsg3%
                }
                FileDelete, %sFile%
            }
        }
        if (tries > 1) {
            WriteLog("Downloaded image after " tries " tries")
        }
        FileAppend, %respHeaders%, %sFileTxt%
    }
    if (FileExist(sFileTxt)) {
        FileRead, respHeaders, %sFileTxt%
    }
    if (FileExist(sFile)) {
        WriteLog("Downloaded " imageUrl " to " sFile)
        foundFields := 0
        Loop, Parse, respHeaders, `r`n
        {  
            WriteLogDebug("Response Header: " A_LoopField)
            
            field := StrSplit(A_LoopField, ":")
            switch (field[1]) {
                case "lefttrimmed": leftTrimmed := Trim(field[2]), foundFields++
                case "toptrimmed": topTrimmed := Trim(field[2]), foundFields++
                case "offsetx": mapOffsetX := Trim(field[2]), foundFields++
                case "offsety": mapOffsety := Trim(field[2]), foundFields++
                case "mapwidth": mapwidth := Trim(field[2]), foundFields++
                case "mapheight": mapheight := Trim(field[2]), foundFields++
                case "exits": exits := Trim(field[2]), foundFields++
                case "waypoint": waypoint := Trim(field[2]), foundFields++
                case "bosses": bosses := Trim(field[2]), foundFields++
                case "quests": quests := Trim(field[2]), foundFields++
                case "prerotated": prerotated := convertToBool(field[2]), foundFields++
                case "originalwidth": originalwidth := Trim(field[2]), foundFields++
                case "originalheight": originalheight := Trim(field[2]), foundFields++
            }
        }
        if (foundFields < 9) {
            WriteLog("ERROR: Did not find all expected response headers, turn on debug mode to view. Unexpected behaviour may occur")
            Loop, Parse, respHeaders, `n
            {
                WriteLog("Response Header: " A_LoopField)
            }
        }
        ; if prerotated returns true at least once then it will be for every other request
        ; this should stop any weird rotation issues
        if (prerotated) {
            serverisv10 := true
        }
        if (serverisv10) {
            prerotated := true
        }
    }
    mapData := { "sFile": sFile, "leftTrimmed" : leftTrimmed, "topTrimmed" : topTrimmed, "levelScale": levelScale, "levelxmargin": levelxmargin, "levelymargin": levelymargin, "mapOffsetX" : mapOffsetX, "mapOffsety" : mapOffsety, "mapwidth" : mapwidth, "mapheight" : mapheight, "exits": exits, "waypoint": waypoint, "bosses": bosses, "quests": quests, "prerotated": prerotated, "originalwidth": originalwidth, "originalheight": originalheight }
} 


convertToBool(field) {
    
    if (Trim(field) == "true")
        return 1
    return 0
}


downloadImageFile(ByRef imageUrl, ByRef sFile) {

    return respHeaders
}