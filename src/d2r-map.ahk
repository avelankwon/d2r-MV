#SingleInstance, Force
#Include %A_ScriptDir%\include\getPlayerOffset.ahk
#Include %A_ScriptDir%\include\getMapUrl.ahk
#Include %A_ScriptDir%\include\getLevelNo.ahk
#Include %A_ScriptDir%\include\getDifficulty.ahk
#Include %A_ScriptDir%\include\getMapSeed.ahk
#Include %A_ScriptDir%\include\showMap.ahk
#Include %A_ScriptDir%\include\logging.ahk

if !FileExist(A_Scriptdir . "\settings.ini") {
	MsgBox, , Missing settings, Could not find settings.ini file
	ExitApp
}
lastMap := ""
WriteLog("*******************************************************")
WriteLog("* Map overlay started *")
WriteLog("*******************************************************")
IniRead, baseUrl, settings.ini, MapHost, baseUrl
IniRead, width, settings.ini, MapSettings, width, 1000
IniRead, topMargin, settings.ini, MapSettings, topMargin, 50
IniRead, leftMargin, settings.ini, MapSettings, leftMargin, 50
IniRead, opacity, settings.ini, MapSettings, opacity, 0.5
IniRead, hideTown, settings.ini, MapSettings, hideTown, true
IniRead, startingOffset, settings.ini, Memory, playerOffset
IniRead, debug, settings.ini, Logging, debug, false

WriteLog("Using configuration:")
WriteLog("    baseUrl: " baseUrl)
WriteLog("    Map: width: " width ", topMargin: " topMargin ", leftMargin: " leftMargin ", opacity: " opacity)
WriteLog("    Hide town map: " hideTown)
WriteLog("    startingOffset: " startingOffset)
WriteLog("    debug logging: " debug)

playerOffset:=startingOffset
windowShow := true

SetTimer, UpdateCycle, 1000 ; the 1000 here is priority, not sleep
SetTimer, CheckScreen, 50
return


CheckScreen:
	IfWinNotActive, ahk_exe D2R.exe
		Gui, 1: Hide
	IfWinActive, ahk_exe D2R.exe
		if (windowShow)
			Gui, 1: Show, NA
return

UpdateCycle:
	; scan for the player offset
	playerOffset := checkLastOffset(playerOffset)
	if (!playerOffset) {
		playerOffset := scanForPlayerOffset(startingOffset)
	}
	if (playerOffset) {
		pSeedAddress := getMapSeedAddress(playerOffset)
		if (pSeedAddress) {
			pDifficultyAddress := getDifficultyAddress(playerOffset)
			pLevelNoAddress := getLevelNoAddress(playerOffset)
			if (pLevelNoAddress) {
				sMapUrl := getD2RMapUrl(baseUrl, pSeedAddress, pDifficultyAddress, pLevelNoAddress)
				if (InStr(lastMap, sMapUrl)) { ; if map not changed then don't update
				} else {
					WriteLog("Fetching map from " sMapUrl)
					lastMap := sMapUrl
					windowShow := true
					ShowMap(sMapUrl, width, leftMargin, topMargin, opacity, hideTown)
				}
			} else {
				windowShow := false
			}
		} else {
			WriteLog("Found playerOffset" playerOffset ", but not map seed address")
			windowShow := false
			playerOffset := startingOffset ; reset the offset to default
		}
	} else {
		playerOffset := startingOffset ; reset the offset to default
		windowShow := false
		Sleep, 5000  ; sleep longer when no offset found, you're likely in menu
	}
	Sleep, 1000 ; set a pacing of 1 second
return

+F10::
{
	WriteLog("Pressed Shift+F10, exiting...")
	ExitApp
}


