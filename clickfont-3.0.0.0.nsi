; Definitions
!define VERSION "3.0.0.0"
!define NAME "ClickFont"
!define PUBSRC

; Header Compression
!packhdr "$%TEMP%\exehead.tmp" "upx.exe --best $%TEMP%\exehead.tmp"

Name "${NAME}"
Caption "${NAME}"
OutFile "clickfont.exe"
RequestExecutionLevel user
SetDatablockOptimize on
SetCompress force
SetCompressor /SOLID lzma
CRCCheck on
ShowInstDetails hide
AutoCloseWindow true

!ifndef PUBSRC
    BrandingText "whyEye.org"
    Icon "ui\default.ico"
    InstallColors 000000 FFFFFF
    InstProgressFlags colored smooth
!else
    BrandingText "http://clickfont.sourceforge.net"
!endif

; Variables
Var Parameter
Var Input
Var Extension
Var File
Var Parent
Var Mode
Var Type
Var Counter
Var reCounter
Var Switches
Var Progress
Var CountInst
Var CountSkip

; Translations
!include "inc\LanguageIDs.nsh"

!ifndef PUBSRC
  !include "inc\_lang_english.nsh"
  !include "inc\lang_*.nsh"
!else
  !include "inc\_lang_english.nsh"
!endif

; Inclusions
!include "WinMessages.nsh"
!include "LogicLib.nsh"
!include "inc\FontRegMod.nsh"
	!insertmacro PostScriptName
!include "FontName.nsh"
!include "Registry.nsh"
!include "FileFunc.nsh"
	!insertmacro GetParameters
	!insertmacro GetOptions
	!insertmacro GetFileName
	!insertmacro GetFileExt
	!insertmacro GetParent
!include "WordFunc.nsh"
	!insertmacro WordReplace
	!insertmacro WordFind
!insertmacro LineRead
!insertmacro LineSum

; Version Information
VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "${NAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Jan T. Sott"
VIAddVersionKey "FileDescription" "${NAME} ${VERSION}"
VIAddVersionKey "Comments" "http://clickfont.sf.net"

; Macros
!macro FontRegistration Extension
  WriteRegStr HKCR "${Extension}file\shell\ClickFont" "" "$(InstallFont)"
  WriteRegExpandStr HKCR "${Extension}file\shell\ClickFont\command" "" '"$EXEDIR\clickfont.exe" %1'
!macroend
!define FontReg "!insertmacro FontRegistration"

; Pages
/*Page InstFiles
*/
; Sections
Section -bla
 # Quit
SectionEnd

; Functions
Function .onInit
	SetSilent silent
	
	InitPluginsDir
	SetOutPath $PLUGINSDIR

	${GetParameters} $Parameter
	
	#MessageBox MB_OK -$Parameter- #delme
	
	;help doesn't require admin rights
	${If} $Parameter == "/help"
	${OrIf} $Parameter == "-help"
	${OrIf} $Parameter == "--help"
	${OrIf} $Parameter == "/?"
	${OrIf} $Parameter == "-?"
	${OrIf} $Parameter == "--?"
		StrCpy $Switches "$Switches$\r$\n/help$\tshow this dialog"
		StrCpy $Switches "$Switches$\r$\n/install$\tassociate with supported files"
		StrCpy $Switches "$Switches$\r$\n/uninstall$\tunassociate with supported files"
		#StrCpy $Switches "$Switches$\r$\n/reset$\treset settings"		
		StrCpy $Switches "$Switches$\r$\n$\r$\nbuilt with NSIS ${NSIS_VERSION}/${NSIS_MAX_STRLEN} [${__DATE__}]"
		
		MessageBox MB_USERICON|MB_OK "${NAME} ${VERSION} Switches:$\r$\n$Switches"
		Quit
	${ElseIf} $Parameter == ""
		Goto NoInput
	${EndIf}
	
	UAC_Elevate:
	UAC::_ 0
	StrCmp 1223 $0 UAC_ElevationAborted ; UAC dialog aborted by user?
	StrCmp 0 $0 0 UAC_Err ; Error?
	StrCmp 1 $1 0 UAC_Success ;Are we the real deal or just the wrapper?
	Quit

	UAC_Err:
	#MessageBox MB_OK|MB_ICONSTOP "Unable to elevate, error $0"
	Abort

	UAC_ElevationAborted:
	# elevation was aborted, run as normal?
	#MessageBox MB_OK|MB_ICONSTOP "This installer requires admin access, aborting!"
	Abort

	UAC_Success:
	StrCmp 1 $3 +4 ;Admin?
	StrCmp 3 $1 0 UAC_ElevationAborted ;Try again?
	MessageBox MB_OK|MB_ICONINFORMATION "This installer requires admin access, try again"
	goto UAC_Elevate
	
	;strip parameters from uac plugin
	${WordFind} $Parameter "/NCRC " "-1" $Parameter
	
	#MessageBox MB_OK -$Parameter- #delme
	
	${If} $Parameter == "/install"
		MSIBanner::Show /NOUNLOAD "${NAME}"
		
		MSIBanner::Pos /NOUNLOAD 25 "Associating with TrueType fonts"
		Sleep 200
		${FontReg} "ttf"
		
		MSIBanner::Pos /NOUNLOAD 50 "Associating with OpenType fonts"
		Sleep 200
		${FontReg} "otf"
		
		MSIBanner::Pos /NOUNLOAD 75 "Associating with PostScript fonts"
		Sleep 200
		${FontReg} "pfm"
		
		MSIBanner::Pos /NOUNLOAD 100 "Associating with directories"
		Sleep 200
		WriteRegStr HKCR "Directory\shell\ClickFont" "" "$(InstallFonts)"
		WriteRegStr HKCR "Directory\shell\ClickFont\command" "" '"$EXEDIR\clickfont.exe" %1'
		
		MSIBanner::Destroy
		Quit
	${ElseIf} $Parameter == "/uninstall"
		MSIBanner::Show /NOUNLOAD "${NAME}"
		
		MSIBanner::Pos /NOUNLOAD 25 "Unassociating with TrueType fonts"
		Sleep 200
		DeleteRegKey HKCR "ttffile\shell\ClickFont"
		
		MSIBanner::Pos /NOUNLOAD 50 "Unassociating with OpenType fonts"
		Sleep 200
		DeleteRegKey HKCR "otffile\shell\ClickFont"
		
		MSIBanner::Pos /NOUNLOAD 75 "Unassociating with PostScript fonts"
		Sleep 200
		DeleteRegKey HKCR "pfmfile\shell\ClickFont"
		
		MSIBanner::Pos /NOUNLOAD 100 "Unassociating with directories"
		Sleep 200
		DeleteRegKey HKCR "Directory\shell\ClickFont"
		
		MSIBanner::Destroy
		Quit		
	#${ElseIf} $Parameter == "/reset"
	#${OrIf} $Parameter == "/flush"
	${EndIf}
	
	${WordReplace} $Parameter '"' "" "+" $Parameter	
	#MessageBox MB_OK -$Parameter- #delme
	
	${If} ${FileExists} $Parameter
	${AndIfNot} ${FileExists} "$Parameter\*.*"
	${AndIf} $Parameter != ""		
		Call GetExtension		
	${ElseIf} ${FileExists} "$Parameter\*.ttf"
	${OrIf} ${FileExists} "$Parameter\*.otf"
	${OrIf} ${FileExists} "$Parameter\*.pfm"
		StrCpy $Mode "dir"
		StrCpy $Input "$Parameter"
	${Else}
		NoInput:
		MessageBox MB_OK|MB_USERICON "${NAME} will do nothing unless you drop a font (or a directory containing fonts) on this executable. If properly installed, you can choose ${NAME} from the context menu of any supported file-type."
		Quit
	${EndIf}

	${GetFileName} $Input $File
	${GetParent} $Input $Parent
	
	#Init Banner
	MSIBanner::Show /NOUNLOAD "${NAME}"

	${If} $Mode == "file" ##### SINGLE FILE #####
	${AndIfNot} ${FileExists} "$FONTS\$File" #refine!
	${AndIf} $Parent != "$FONTS"
		MSIBanner::Pos /NOUNLOAD 0 "Installing '$File'" #$(InstallProgress)
		${If} $Extension == "pfm"
			!insertmacro InstallPostScript "$Input"
		${Else}
			!insertmacro InstallFont "$Input"
		${EndIf}
		SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=5000
		Sleep 500
		MSIBanner::Pos /NOUNLOAD 100 "Completed"
	${ElseIf} $Mode == "file"
	${AndIf} ${FileExists} "$FONTS\$File"
	${OrIf} $Parent == "$FONTS"
		#MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Font already installed, do you want to overwrite it?" IDYES installFont
		MSIBanner::Pos /NOUNLOAD 100 "Skipped '$File', file exists"
	${ElseIf} $Mode == "dir" ##### DIRECTORY #####
		StrCpy $Counter 0
		${Locate} "$Input" "/L=F /G=1 /M=*.*" "fontArray" #/SD=NAME /SF=NAME"	
		nsArray::Sort fontDir 16 #descending order!
		
		StrCpy $9 $Counter
		Math::Script "R9 = 100.0/r9"
		StrCpy $9 "0" ;r0
		
		StrCpy $CountInst 0
		StrCpy $CountSkip 0
		
		StrCpy $reCounter 0
		${While} $reCounter < $Counter		
			nsArray::Get fontDir $reCounter
			Pop $Input
			nsArray::Remove fontDir $reCounter #not sure why, but it's better ;)
			
			${GetFileName} $Input $File
			${GetFileExt} $Input $Extension
			${GetParent} $Input $Parent
			
			Math::Script "r9 = r9+R9"
			IntOp $Progress $9 + 0 #rounding
			
			${If} ${FileExists} "$FONTS\$File" #refine
			${AndIf} "$File" != ""
			${OrIf} $Parent == "$FONTS"
				MSIBanner::Pos /NOUNLOAD $Progress "Skipped '$File', file exists"
				#Sleep 1000 #delme
				IntOp $CountSkip $CountSkip + 1
			${ElseIf} $File != ""
				MSIBanner::Pos /NOUNLOAD $Progress "Installing '$File'"
				
				${If} $Extension == "ttf"
				${OrIf} $Extension == "otf"
					!insertmacro InstallFont "$Input"
				${ElseIf} $Extension == "pfm"
					!insertmacro InstallPostScript "$Input"
				${EndIf}
				SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=5000
				IntOp $CountInst $CountInst + 1
			${EndIf}
			
			IntOp $reCounter $reCounter + 1
		${EndWhile}
		
		MSIBanner::Pos /NOUNLOAD 100 "Completed ($CountInst installed/$CountSkip skipped)"
	${EndIf}
	
	Sleep 1000
	MSIBanner::Destroy
FunctionEnd

Function fontArray
	${GetFileExt} "$R7" $0
	${If} $0 == "ttf"
	${OrIf} $0 == "otf"
	${OrIf} $0 == "pfm"
		nsArray::Set fontDir /key=$Counter $R9 /end
		IntOp $Counter $Counter + 1
	${EndIf}
	
	Push $0
FunctionEnd

Function GetExtension
	${GetFileExt} $Parameter $Extension
	
	${If} $Extension == "ttf"
	${OrIf} $Extension == "otf"
	${OrIf} $Extension == "pfm"
		StrCpy $Mode "file"
		StrCpy $Input $Parameter
	${Else}
		MessageBox MB_OK|MB_ICONEXCLAMATION "?ERROR: Filetype not supported"
		Quit
	${EndIf}
FunctionEnd


