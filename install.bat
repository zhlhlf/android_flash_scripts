@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 03
powershell -Command "$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(75, 30)"
title �ײ��ϵͳˢ��   by zhlhlf

:: ȫ�ֱ���������Ƿ�Ϊ�ٷ�ˢ��ģʽ
set "OFFICIAL_MODE="

goto main

:main
cls
echo --------------------------------------------------------
echo ������Ϊŷ����ab���� �ײ��ϵͳˢ�빤��
echo ��ȷ���ֻ���fastboot or bootloaderģʽ��
echo                                            ----by zhlhlf
echo --------------------------------------------------------
echo --------------------------------------------------------
echo                       ������
echo.
echo 1.ˢ��FW��ROM������ˢ�� �ǹٷ���
echo 2.ˢ��FW��ROM������ˢ�� �ٷ�����
echo 3.��ˢ��FW���ײ㣩
echo 4.��ˢ��ROM��ϵͳ��
echo 5.���data���ݣ�����fastbootdģʽ��
echo 0.�˳�����
echo --------------------------------------------------------
echo.
echo.

:input
set /p "id=������ѡ�"
if not defined id goto input

rem ����ѡ�����Ӧ��ǩ��ӳ���ϵ
set "options=1:fw_and_rom 2:fw_and_rom1 3:fw 4:rom 5:wipe_data 0:exit"

for %%a in (%options%) do (
    for /f "tokens=1,2 delims=:" %%b in ("%%a") do (
        if "%id%"=="%%b" (
            call :%%c
        )
    )
)

pause
goto main

:: �ǹٷ�ˢ�루������֤��
:fw_and_rom
echo ����ˢ��fw��rom...
set "OFFICIAL_MODE=false"
call :fw
call :rom
call :wipe_data
echo.����..
tools\fastboot reboot
pause
goto :eof

:: �ٷ�ˢ�루������֤��
:fw_and_rom1
echo ����ˢ��fw��rom...
set "OFFICIAL_MODE=true"
call :fw
call :rom
call :wipe_data
echo.����..
tools\fastboot reboot
pause
goto :eof

:fw
cls
set fw_path=firmware-update
tools\adb shell reboot bootloader >nul 2>&1

if exist %fw_path%\modem.img (
    echo ˢ��modem��..
    tools\fastboot flash modem %fw_path%\modem.img
)

echo ����fastboot...
tools\fastboot reboot fastboot

for %%i in (%fw_path%\*.img) do (
    set filename=%%~nxi
    set filename=!filename:modem=!

    if "!filename!"=="%%~nxi" (
        set filename=%%~ni
        tools\fastboot flash !filename! %%i
    )
)

echo --------------------------------------------------------
echo "ˢ��fw�ײ����"
echo --------------------------------------------------------
goto :eof


:wipe_data
echo �Ƿ����data���ݣ�
:confirm_input
set /p "confirm=������[y/n]��"
if /i "%confirm%"=="y" (
    echo �������data����...
    tools\fastboot -w
    echo data�����������
    goto :eof
) else if /i "%confirm%"=="n" (
    echo ��ȡ��������
    goto :eof
) else (
    echo ������Ч�����������룡
    goto confirm_input
)
goto :eof

:wipe_logic_part
echo ������ж�̬����...
for /f "tokens=2 delims=:" %%a in ('tools\fastboot getvar all 2^>^&1 ^| findstr /r /c:"(bootloader) is-logical:.*:yes"') do (
    tools\fastboot delete-logical-partition %%a
)
goto :eof

:rom
cls
echo --------------------------------------------------------
echo ˢ��ϵͳ�Ȳ���...
echo ---------------------------------------------------------

set images_path=images
set "flash_files="
set "slot="

if exist images\super.zst tools\zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    tools\fastboot flash super images\super.img
) else (
    for /f "tokens=2 delims=: " %%i in ('tools\fastboot getvar current-slot 2^>^&1 ^| findstr /r /c:"current-slot:"') do (
        set slot=%%i
    )

    if "!slot!"=="" (
        echo δ�ܻ�ȡ��ǰ��λ��Ϣ ��������˳�����
        pause
        exit /b 1
    )
    call :wipe_logic_part

    echo �������趯̬����...
    for %%i in (%images_path%\*.img) do (
        set filename=%%~nxi
        set filename=!filename:vbmeta=!
        set filename=!filename:boot=!
        set filename=!filename:dtbo=!

        if "!filename!"=="%%~nxi" (
            ::  �߼���������
            set filename=%%~ni
            set "partition=!filename!"
            set "flash_files=!flash_files! !partition!"
            set "partition=!filename!_!slot!"
            tools\fastboot create-logical-partition !partition! 1
        )
    )
    echo super_list: !flash_files!
    echo ˢ��images...
    for %%i in (!flash_files!) do (
        tools\fastboot flash %%i images\%%i.img
    )
)

for %%i in (
    "%images_path%\*boot*.img"
    "%images_path%\dtbo.img"
) do (
    if exist "%%i" (
        set "filename=%%~ni"
        tools\fastboot flash !filename! "%%i"
    )
)

:: ���ݹٷ�/�ǹٷ�ģʽ����vbmetaˢ�뷽ʽ
for %%i in ("%images_path%\vbmeta*.img") do (
    set "filename=%%~ni"
    if "!OFFICIAL_MODE!"=="true" (
        echo [�ٷ�ģʽ] ˢ�� !filename! ������֤����
        tools\fastboot flash !filename! "%%i"
    ) else (
        echo [�ǹٷ�ģʽ] ˢ�� !filename! ��--disable-verity --disable-verification����
        tools\fastboot flash !filename! "%%i" --disable-verity --disable-verification
    )
)

call :wipe_data

goto :eof


:exit

exit



endlocal
