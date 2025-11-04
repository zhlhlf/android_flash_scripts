@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 03
powershell -Command "$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(75, 30)"
title 底层和系统刷入   by zhlhlf

:: 全局变量，标记是否为官方刷入模式
set "OFFICIAL_MODE="
set "PATH=tools;%PATH%"

goto main

:main
cls
echo --------------------------------------------------------
echo 本程序为欧加真ab分区 底层和系统刷入工具
echo 请确认手机在fastboot or bootloader模式下
echo                                            ----by zhlhlf
echo --------------------------------------------------------
echo --------------------------------------------------------
echo                       请输入
echo.
echo 1.刷入FW和ROM（完整刷机 非官方）
echo 2.刷入FW和ROM（完整刷机 官方包）
echo 3.仅刷入FW（底层）
echo 4.仅刷入ROM（系统）
echo 5.清除data数据（需在fastbootd模式）
echo 0.退出程序
echo --------------------------------------------------------
echo.
echo.

:input
set /p "id=请输入选项："
if not defined id goto input

rem 定义选项与对应标签的映射关系
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

:: 非官方刷入（禁用验证）
:fw_and_rom
echo 正在刷入fw和rom...
set "OFFICIAL_MODE=false"
call :fw
call :rom
echo.重启..
fastboot reboot
goto :eof

:: 官方刷入（保持验证）
:fw_and_rom1
echo 正在刷入fw和rom...
set "OFFICIAL_MODE=true"
call :fw
call :rom
echo.重启..
fastboot reboot
goto :eof

:fw
cls
set fw_path=firmware-update
adb shell reboot bootloader >nul 2>&1

if exist %fw_path%\modem.img (
    echo 刷入modem中..
    fastboot flash modem %fw_path%\modem.img
)

echo 进入fastboot...
fastboot reboot fastboot

for %%i in (%fw_path%\*.img) do (
    set filename=%%~nxi
    set filename=!filename:modem=!

    if "!filename!"=="%%~nxi" (
        set filename=%%~ni
        fastboot flash !filename! %%i
    )
)

echo --------------------------------------------------------
echo "刷入fw底层完成"
echo --------------------------------------------------------
goto :eof


:wipe_data
echo 是否清除data数据？
:confirm_input
set /p "confirm=请输入[y/n]："
if /i "%confirm%"=="y" (
    echo 正在清除data数据...
    fastboot -w
    echo data数据已清除！
    goto :eof
) else if /i "%confirm%"=="n" (
    echo 已取消操作。
    goto :eof
) else (
    echo 输入无效，请重新输入！
    goto confirm_input
)
goto :eof

:wipe_logic_part
echo 清除所有动态分区...
for /f "tokens=2 delims=:" %%a in ('fastboot getvar all 2^>^&1 ^| findstr /r /c:"(bootloader) is-logical:.*:yes"') do (
    fastboot delete-logical-partition %%a
)
goto :eof

:rom
cls
echo --------------------------------------------------------
echo 刷入系统等操作...
echo ---------------------------------------------------------

set images_path=images
set "flash_files="
set "slot="

if exist images\super.zst zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    fastboot flash super images\super.img
) else (
    for /f "tokens=2 delims=: " %%i in ('fastboot getvar current-slot 2^>^&1 ^| findstr /r /c:"current-slot:"') do (
        set slot=%%i
    )

    if "!slot!"=="" (
        echo 未能获取当前槽位信息 按任意键退出！。
        pause
        exit /b 1
    )
    call :wipe_logic_part

    echo 创建所需动态分区...
    for %%i in (%images_path%\*.img) do (
        set filename=%%~nxi
        set filename=!filename:vbmeta=!
        set filename=!filename:boot=!
        set filename=!filename:dtbo=!

        if "!filename!"=="%%~nxi" (
            ::  逻辑分区部分
            set filename=%%~ni
            set "partition=!filename!"
            set "flash_files=!flash_files! !partition!"
            set "partition=!filename!_!slot!"
            fastboot create-logical-partition !partition! 1
        )
    )
    echo super_list: !flash_files!
    echo 刷入images...
    for %%i in (!flash_files!) do (
        fastboot flash %%i images\%%i.img
    )
)

for %%i in (
    "%images_path%\*boot*.img"
    "%images_path%\dtbo.img"
) do (
    if exist "%%i" (
        set "filename=%%~ni"
        fastboot flash !filename! "%%i"
    )
)

:: 根据官方/非官方模式决定vbmeta刷入方式
for %%i in ("%images_path%\vbmeta*.img") do (
    set "filename=%%~ni"
    if "!OFFICIAL_MODE!"=="true" (
        echo [官方模式] 刷入 !filename! 不带验证参数
        fastboot flash !filename! "%%i"
    ) else (
        echo [非官方模式] 刷入 !filename! 带--disable-verity --disable-verification参数
        fastboot flash !filename! "%%i" --disable-verity --disable-verification
    )
)

call :wipe_data

goto :eof


:exit

exit



endlocal
