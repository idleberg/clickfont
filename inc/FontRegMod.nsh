#var FONT_DIR

!ifndef CSIDL_FONTS
  !define CSIDL_FONTS '0x14' ;Fonts directory path constant
!endif
!ifndef CSIDL_FLAG_CREATE
  !define CSIDL_FLAG_CREATE 0x8000
!endif

!macro InstallFont FontFile
  Push $0
  Push $R0
  Push $R1
  Push $R2
  
  !define Index 'Line${__LINE__}'

# SetOutPath $FONTS
  IfFileExists "$FONTS\$File" ${Index}
  CopyFiles '${FontFile}' "$FONTS\$File"

${Index}:
  ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
  IfErrors "${Index}-9x" "${Index}-NT"

"${Index}-NT:"
  StrCpy $R1 "Software\Microsoft\Windows NT\CurrentVersion\Fonts"
  goto "${Index}-GO"

"${Index}-9x:"
  StrCpy $R1 "Software\Microsoft\Windows\CurrentVersion\Fonts"
  goto "${Index}-GO"

"${Index}-GO:"
  ClearErrors
  StrCmp $Extension "ttf" 0 "${Index}-Add"
  !insertmacro FontName "${FontFile}"
  pop $R2
  IfErrors 0 "${Index}-Add"
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION|MB_DEFBUTTON1 "?ERROR: $R2" IDOK +2
  Quit

"${Index}-Add:"
  ${If} $Extension == "ttf"
  	StrCpy $Type "$R2 (TrueType)"
  ${ElseIf} $Extension == "otf"
  	StrCpy $Type "$R2 (OpenType)"
  ${EndIf}

  StrCpy $R2 "$Type"
  
  ClearErrors
  ReadRegStr $R0 HKLM "$R1" "$R2"
  IfErrors 0 "${Index}-End"
    System::Call "GDI32::AddFontResourceA(t) i ('$File') .s"
    WriteRegStr HKLM "$R1" "$R2" "$File"
    goto "${Index}-End"

"${Index}-End:"

  !undef Index

  pop $R2
  pop $R1
  Pop $R0
  Pop $0
!macroend

## POSTSCRIPT FUNCTION
!ifndef POSTSCRIPTNAME_INCLUDED
!define POSTSCRIPTNAME_INCLUDED

!verbose push
!verbose 3
!ifndef _POSTSCRIPTNAME_VERBOSE
	!define _POSTSCRIPTNAME_VERBOSE 3
!endif
!verbose ${_POSTSCRIPTNAME_VERBOSE}
!define POSTSCRIPTNAME_VERBOSE `!insertmacro POSTSCRIPTNAME_VERBOSE`
!define _POSTSCRIPTNAME_UN
!define _POSTSCRIPTNAME_S
!verbose pop

!macro POSTSCRIPTNAME_VERBOSE _VERBOSE
	!verbose push
	!verbose 3
	!undef _POSTSCRIPTNAME_VERBOSE
	!define _POSTSCRIPTNAME_VERBOSE ${_VERBOSE}
	!verbose pop
!macroend


!macro AddFileFunc FuncInc FuncName
  !ifndef ${FuncName}
    !include ${FuncInc}.nsh
    !insertmacro ${FuncName}
  !endif
!macroend

!insertmacro AddFileFunc FileFunc GetBaseName 
!insertmacro AddFileFunc FileFunc GetParent
!insertmacro AddFIleFunc TextFunc ConfigRead
#!insertmacro PostScriptName

!macro InstallPostScript FontPath
  Push $0
  Push $R0
  Push $R1
  Push $R2
 
  !define Index 'Line${__LINE__}'
   
  ${GetBaseName} "${FontPath}" $0
  !define FontBase $0
  ${GetParent} "${FontPath}" $1
  !define SourceDir $1
  !define FontName $2
 
  SetOutPath $FONTS
  IfFileExists "$FONTS\${FontBase}.pfm" ${Index}
  CopyFiles '${FontPath}' "$FONTS"
 
${Index}:
  ClearErrors
  ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
  IfErrors "${Index}-Error" "${Index}-GO"
 
"${Index}-Error:"
  MessageBox MB_OK|MB_ICONEXCLAMATION "$(PostScriptWarning)"
  goto "${Index}-End"
 
"${Index}-GO:"
  ClearErrors
  ${PostScriptName} "${SourceDir}" "${FontBase}" "${FontName}"
  IfErrors 0 "${Index}-Add"
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION|MB_DEFBUTTON1 "?ERROR: ${FontBase}.pfm" IDOK +2
  Quit
 
"${Index}-Add:"
  ClearErrors
  ${registry::Write} "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Type 1 Installer\Type 1 Fonts" "${FontName}" "T ${FontBase}.pfm ${FontBase}.pfb" "REG_MULTI_SZ" $R0
  System::Call "GDI32::AddFontResourceA(t) i ('${FontBase}.pfm|${FontBase}.pfb') .s"
  goto "${Index}-End"
 
"${Index}-End:"
 
  !undef Index
  !undef FontBase
  !undef SourceDir
  !undef FontName
 
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $0
!macroend

!macro PostScriptNameCall _PATH _NAME _RESULT
       !verbose push
       !verbose ${_POSTSCRIPTNAME_VERBOSE}
       Push `${_PATH}`
       Push `${_NAME}`
       Call PostScriptName
       Pop `${_RESULT}`
       !verbose pop
!macroend

!macro PostScriptName
	!ifndef ${_POSTSCRIPTNAME_UN}PostScriptName${_POSTSCRIPTNAME_S}
		!verbose push
		!verbose ${_POSTSCRIPTNAME_VERBOSE}
		!define ${_POSTSCRIPTNAME_UN}PostScriptName${_POSTSCRIPTNAME_S} `!insertmacro ${_POSTSCRIPTNAME_UN}PostScriptName${_POSTSCRIPTNAME_S}Call`

		Function PostScriptName
			Exch $R2 ;sourcedir
			Exch
			Exch $R1 ;base
			Push $R0
    
			${If} ${FileExists} "$R1\$R2.afm"
				${ConfigRead} "$R1\$R2.afm" "FullName " $R0
				StrCmp $R0 "" 0 +2
				Goto InfRead
			${ElseIf} ${FileExists} "$R1\$R2.inf"
				InfRead:
				${ConfigRead} "$R1\$R2.inf" "FullName " $R0
				StrCpy $0 $R0 1     ;get first char
				StrCmp $0 "(" 0 +2  ;check if first char matches "("
				StrCpy $R0 $R0 "" 1 ;delete first char
				StrCpy $0 $R0 "" -1 ;get last char
				StrCmp $0 ")" 0 +2  ;check if last char matches ")"
				StrCpy $R0 $R0 -1   ;delete last char
			${EndIf}
  
			${If} $R0 == ""
				StrCpy $R0 "$R1"
			${EndIf}

			StrCpy $R0 "$R0 (Type1)"

			Pop $R2
			Pop $R1
			Exch $R0
		FunctionEnd
		
		!verbose pop
	!endif
!macroend

!endif