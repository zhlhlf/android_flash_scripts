@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 0a
powershell -Command "$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(75, 30)"
title �ײ��ϵͳˢ��   by zhlhlf

goto main

:main
cls
echo --------------------------------------------------------
echo ������Ϊab���� �ײ��ϵͳˢ�빤��
echo ��ȷ���ֻ���fastboot or bootloaderģʽ��
echo                                            ----by zhlhlf
echo --------------------------------------------------------
echo --------------------------------------------------------
echo                       ������
echo.
echo 1.����"ddr4",����ˢ��ddr4�ڴ��͵ĵײ㡣
echo 2.����"ddr5",����ˢ��ddr5�ڴ��͵ĵײ㡣
echo 3.����"1",��ˢ��ϵͳ��
echo 4.����"0"��Ϊ�˳���
echo --------------------------------------------------------
echo.
echo.
set /p id="������ѡ�"

set "options[0]=ddr4"
set "options[1]=ddr5"
set "options[2]=1"
set "options[3]=0"

set "labels[0]=ddr4"
set "labels[1]=ddr5"
set "labels[2]=system"
set "labels[3]=exit"

for /l %%i in (0,1,3) do (
    if "%id%"=="!options[%%i]!" (
        goto !labels[%%i]!
    )
)

goto main

:ddr4
echo --------------------------------------------------------
echo ˢ��ddr4�ĵײ�...
echo --------------------------------------------------------
tools\fastboot reboot fastboot

call :fw
set list=xbl_config xbl imagefv
for %%i in (!list!) do (
    tools\fastboot flash %%i firmware-update\%%i.img
)

cls
echo --------------------------------------------------------
echo "ˢ��ײ����        ��ˢ��������  %id%"  
echo --------------------------------------------------------
pause

goto main

:ddr5
echo --------------------------------------------------------
echo ˢ��ddr5�ĵײ�...
echo --------------------------------------------------------
tools\fastboot reboot fastboot

call :fw
set list=xbl_config xbl imagefv
for %%i in (!list!) do (
    set "partition=%%i"
    set "partition_final=!partition!_ddr5"
    tools\fastboot flash %%i firmware-update\!partition_final!.img
)

cls
echo --------------------------------------------------------
echo "ˢ��ײ����        ��ˢ��������  %id%"  
echo --------------------------------------------------------
pause
goto main


:fw
set fw_path=firmware-update

for %%i in (%fw_path%\*.img) do (
        set filename=%%~nxi
        set filename=!filename:_lp5=!

        if "!filename!"=="%%~nxi" (
            set filename=%%~ni
            tools\fastboot flash !filename! %%i
        )
)

goto :eof

:system

cls
echo --------------------------------------------------------
echo ˢ��ϵͳ�Ȳ���...
echo ---------------------------------------------------------

set images_path=images

if exist images\super.zst tools\zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    tools\fastboot flash super images\super.img
) else (

    for %%i in (%images_path%\*.img) do (
        set filename=%%~nxi
        set filename=!filename:vbmeta=!
        set filename=!filename:boot=!
        set filename=!filename:dtbo=!

        if "!filename!"=="%%~nxi" (
::  �߼���������
            set filename=%%~ni
            set "partition=!filename!
            set "partition_cow=!partition!-cow"
            set "partition_a=!partition!_a"
            set "partition_b=!partition!_b"
::            tools\fastboot delete-logical-partition !partition!
            tools\fastboot delete-logical-partition !partition_a!
            tools\fastboot delete-logical-partition !partition_b!
            tools\fastboot delete-logical-partition !partition_cow!
            tools\fastboot create-logical-partition !partition_a! 1
            tools\fastboot create-logical-partition !partition_b! 1
            tools\fastboot flash !partition! %%i
        )
    )
)
cls

::  boot����
for %%i in (%images_path%\*boot*.img) do (
    set filename=%%~ni
    tools\fastboot flash !filename! %%i
)

::  dtbo����
tools\fastboot flash dtbo %images_path%\dtbo.img

::  vbmeta����
for %%i in (%images_path%\vbmeta*.img) do (
    set filename=%%~ni
    tools\fastboot flash !filename! %%i  --disable-verity --disable-verification 
)

echo.������rec...
tools\fastboot reboot recovery
pause
goto main

:exit
echo --------------------------------------------------------
echo                                    ˢ�����...
echo --------------------------------------------------------
exit

endlocal