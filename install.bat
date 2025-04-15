@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 03
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
echo 1.刷入FW和ROM（完整刷机）
echo 2.仅刷入FW（底层/固件）
echo 3.仅刷入ROM（系统）
echo 4.清除data数据（需在fastbootd模式）
echo 0.退出程序
echo --------------------------------------------------------
echo.
echo.

:input
set /p "id=请输入选项："
if not defined id goto input

rem 定义选项与对应标签的映射关系
set "options=1:fw_and_rom 2:fw 3:rom 4:wipe_data 0:exit"

for %%a in (%options%) do (
    for /f "tokens=1,2 delims=:" %%b in ("%%a") do (
        if "%id%"=="%%b" (
            call :%%c
        )
    )
)

pause
goto main

:fw_and_rom
echo 正在刷入fw和rom...
call :fw
call :rom
echo fw和rom刷入完成！
goto :eof

:fw
cls
set fw_path=firmware-update
echo 需要手机进入 bootloader 或者 fastbootd 状态

echo 重新进入bootloader...
tools\fastboot reboot bootloader

if exist %fw_path%\modem.img (
    echo 刷入modem中..
    tools\fastboot flash modem %fw_path%\modem.img
)

echo 重新进入fastboot...
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
echo "刷入fw底层完成"
echo --------------------------------------------------------

goto :eof

:wipe_data
echo 即将清除data数据，请确保手机已进入fastbootd模式！
:confirm_input
set /p "confirm=请输入[y/n]："
if /i "%confirm%"=="y" (
    echo 正在清除data数据...
    tools\fastboot -w
    echo data数据已清除！
    goto :eof
) else if /i "%confirm%"=="n" (
    echo 已取消操作。
    goto :eof
) else (
    echo 输入无效，请重新输入！
    goto confirm_input
)

:rom
cls
echo --------------------------------------------------------
echo 刷入系统等操作...
echo ---------------------------------------------------------

set images_path=images
set "flash_files="
set "slot="

if exist images\super.zst tools\zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    tools\fastboot flash super images\super.img
) else (
    for /f "tokens=2 delims=: " %%i in ('fastboot getvar current-slot 2^>^&1 ^| findstr /r /c:"current-slot:"') do (
        set slot=%%i
    )

    if "!slot!"=="" (
        echo 未能获取当前槽位信息 按任意键退出！。
        pause
        exit /b 1
    )

    for %%i in (%images_path%\*.img) do (
        set filename=%%~nxi
        set filename=!filename:vbmeta=!
        set filename=!filename:boot=!
        set filename=!filename:dtbo=!

        if "!filename!"=="%%~nxi" (
::  逻辑分区部分
            set filename=%%~ni
            set "partition=!filename!"
            set "partition_a-cow=!partition!_a-cow"
            set "partition_b-cow=!partition!_b-cow"
            set "partition_a=!partition!_a"
            set "partition_b=!partition!_b"

            set "flash_files=!flash_files! !partition!"

            tools\fastboot delete-logical-partition !partition_a!
            tools\fastboot delete-logical-partition !partition_b!
            tools\fastboot delete-logical-partition !partition_a-cow!
            tools\fastboot delete-logical-partition !partition_b-cow!
            set "partition=!filename!_!slot!"
            tools\fastboot create-logical-partition !partition! 1

        )
    )
    echo super_list: !flash_files!

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

for %%i in ("%images_path%\vbmeta*.img") do (
    set "filename=%%~ni"
    tools\fastboot flash !filename! "%%i" --disable-verity --disable-verification
)

call :wipe_data

echo.重启..
tools\fastboot reboot
pause
goto :eof


:exit

exit

endlocal