@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 0a
powershell -Command "$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(75, 30)"
title 底层和系统刷入   by zhlhlf

goto main

:main
cls
echo --------------------------------------------------------
echo 本程序为ab分区 底层和系统刷入工具
echo 请确认手机在fastboot or bootloader模式下
echo                                            ----by zhlhlf
echo --------------------------------------------------------
echo --------------------------------------------------------
echo                       请输入
echo.
echo 1.输入"ddr4",则是刷入ddr4内存型的底层。
echo 2.输入"ddr5",则是刷入ddr5内存型的底层。
echo 3.输入"1",则刷入系统。
echo 4.输入"0"则为退出。
echo --------------------------------------------------------
echo.
echo.
set /p id="请输入选项："

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
echo 刷入ddr4的底层...
echo --------------------------------------------------------
tools\fastboot reboot fastboot

call :fw
set list=xbl_config xbl imagefv
for %%i in (!list!) do (
    tools\fastboot flash %%i firmware-update\%%i.img
)

cls
echo --------------------------------------------------------
echo "刷入底层完成        你刷的类型是  %id%"  
echo --------------------------------------------------------
pause

goto main

:ddr5
echo --------------------------------------------------------
echo 刷入ddr5的底层...
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
echo "刷入底层完成        你刷的类型是  %id%"  
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
echo 刷入系统等操作...
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
::  逻辑分区部分
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

::  boot部分
for %%i in (%images_path%\*boot*.img) do (
    set filename=%%~ni
    tools\fastboot flash !filename! %%i
)

::  dtbo部分
tools\fastboot flash dtbo %images_path%\dtbo.img

::  vbmeta部分
for %%i in (%images_path%\vbmeta*.img) do (
    set filename=%%~ni
    tools\fastboot flash !filename! %%i  --disable-verity --disable-verification 
)

echo.重启到rec...
tools\fastboot reboot recovery
pause
goto main

:exit
echo --------------------------------------------------------
echo                                    刷入完成...
echo --------------------------------------------------------
exit

endlocal