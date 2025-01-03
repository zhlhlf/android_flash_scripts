@echo off
setlocal enabledelayedexpansion
mode con cols=75 lines=138&color 0a
powershell -Command "$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(75, 30)"
title 底层和系统刷入   by zhlhlf

goto main

:main
cls
echo --------------------------------------------------------
echo 本程序为ab分区 底层刷入和系统刷入工具
echo 请确认手机在fastboot模式下
echo 请确认自己手机内存类型 别瞎鸡儿乱刷 刷错底层为砖
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
#tools\fastboot reboot fastboot

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
set list=abl aop bluetooth cmnlib cmnlib64 devcfg dsp featenabler hyp imagefv keymaster logo mdm_oem_stanvbk modem multiimgoem qupfw spunvm storsec tz uefisecapp xbl xbl_config recovery

for %%i in (!list!) do (
    if exist firmware-update\%%i.img (
        tools\fastboot flash %%i firmware-update\%%i.img
    ) else (
        echo firmware-update/%%i.img 不存在
    )
)
goto :eof

:system
cls
echo --------------------------------------------------------
echo 刷入系统等操作...
echo ---------------------------------------------------------

if exist images\super.zst tools\zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    tools\fastboot flash super images\super.img
) else (

    set list=odm system system_ext product vendor 
    set list2=my_bigball my_carrier my_company my_engineering my_heytap my_manifest my_preload my_product my_region my_stock

    echo 清除逻辑分区...

    for %%i in (!list!) do (
        set "partition=%%i"
        set "partition_cow=%%i-cow"
        set "partition_a=!partition!_a"
        set "partition_b=!partition!_b"
        tools\fastboot delete-logical-partition !partition_a!
        tools\fastboot delete-logical-partition !partition_b!
        tools\fastboot delete-logical-partition !partition_cow!
    )

    for %%i in (!list2!) do (
        set "partition=%%i"
        set "partition_cow=%%i-cow"
        set "partition_a=!partition!_a"
        set "partition_b=!partition!_b"
        tools\fastboot delete-logical-partition !partition_a!
        tools\fastboot delete-logical-partition !partition_b!
        tools\fastboot delete-logical-partition !partition_cow!
    )

    cls

    echo 刷入分区...

    for %%i in (!list!) do (
        set "partition=%%i"
        set "partition_a=!partition!_a"
        set "partition_b=!partition!_b"
        tools\fastboot create-logical-partition !partition_a! 1
        tools\fastboot create-logical-partition !partition_b! 1
        tools\fastboot flash %%i images\%%i.img
    )

    if exist images\my_product.img (
        for %%i in (!list2!) do (
            set "partition=%%i"
            set "partition_a=!partition!_a"
            set "partition_b=!partition!_b"
            tools\fastboot create-logical-partition !partition_a! 1
            tools\fastboot create-logical-partition !partition_b! 1
            tools\fastboot flash %%i images\%%i.img
        )
    )
)

set list=boot dtbo
for %%i in (!list!) do (
    tools\fastboot flash %%i images\%%i.img
)

set list=vbmeta vbmeta_system
for %%i in (!list!) do (
    tools\fastboot flash %%i images\%%i.img --disable-verity --disable-verification 
)

echo.重启到rec...
tools\fastboot reboot recovery
pause
goto main

:exit
echo --------------------------------------------------------
echo                                    锟斤拷锟斤拷锟剿筹拷...
echo --------------------------------------------------------
exit

endlocal