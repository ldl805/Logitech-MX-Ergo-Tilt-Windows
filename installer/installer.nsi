!include "MUI2.nsh"

!define APP_NAME "Logitech MX Ergo Tilt Remapper"
!define COMP_NAME "ldl805"
!define VERSION "1.0.0"
!define EXE_NAME "MxErgoTiltRemap.exe"
!define TASK_NAME "MxErgoTiltRemap"
!define UNINSTALL_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\MxErgoTiltRemap"

Name "${APP_NAME} ${VERSION}"
OutFile "..\dist\Logitech-MX-Ergo-Tilt-Windows-Setup-v${VERSION}.exe"
InstallDir "$LOCALAPPDATA\MxErgoTiltRemap"
RequestExecutionLevel admin
ShowInstDetails show
ShowUninstDetails show

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Install" SecMain
    SetOutPath "$INSTDIR"

    DetailPrint "Stopping any running instance of ${EXE_NAME}..."
    nsExec::ExecToLog 'taskkill /F /IM "${EXE_NAME}"'

    File "..\dist\${EXE_NAME}"
    File "..\src\MxErgoTiltRemap.cs"
    File "..\README.md"
    File "..\LICENSE"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    DetailPrint "Registering Windows Scheduled Task (${TASK_NAME})..."
    nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$$action = New-ScheduledTaskAction -Execute \"$INSTDIR\${EXE_NAME}\"; $$trigger = New-ScheduledTaskTrigger -AtLogOn; $$principal = New-ScheduledTaskPrincipal -UserId $$env:USERNAME -LogonType Interactive -RunLevel Highest; $$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero); Register-ScheduledTask -TaskName \"${TASK_NAME}\" -Action $$action -Trigger $$trigger -Principal $$principal -Settings $$settings -Force | Out-Null; Start-ScheduledTask -TaskName \"${TASK_NAME}\""'

    WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
    WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "Publisher" "${COMP_NAME}"
    WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayVersion" "${VERSION}"
    WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoRepair" 1

    DetailPrint "${APP_NAME} is now running in the background!"
SectionEnd

Section "Uninstall"
    DetailPrint "Stopping ${EXE_NAME}..."
    nsExec::ExecToLog 'taskkill /F /IM "${EXE_NAME}"'

    DetailPrint "Removing Scheduled Task (${TASK_NAME})..."
    nsExec::ExecToLog 'schtasks /Delete /TN "${TASK_NAME}" /F'

    Delete "$INSTDIR\${EXE_NAME}"
    Delete "$INSTDIR\MxErgoTiltRemap.cs"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"

    Delete "$SMSTARTUP\MxErgoTiltRemap.lnk"
    DeleteRegKey HKLM "${UNINSTALL_REG_KEY}"
SectionEnd
