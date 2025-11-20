@echo off
mode con cols=75 lines=35&color 03
title 底层和系统安装器   by zhlhlf
goto main
:main
cls
echo --------------------------------------------------------
echo 本程序为一加9r 底层安装和系统刷入工具(单A分区版)
echo 请确认手机在bootloader模式下
echo 请确认自己手机内存类型 别瞎鸡儿乱刷 刷错底层为砖
echo                                            ----by zhlhlf
echo --------------------------------------------------------
echo --------------------------------------------------------
echo                       请输入
echo.
echo 1.输入"ddr4",则是安装ddr4内存型的底层。
echo 2.输入"ddr5",则是安装ddr5内存型的底层。
echo 3.输入"1",则安装系统。
echo 4.输入"0"则为退出。
echo --------------------------------------------------------
set /p id=
if "%id%"=="ddr4" set next_step=0
if "%id%"=="ddr5" set next_step=1
if "%id%"=="1" set next_step=2
if "%id%"=="0" set next_step=3
if %next_step%==0 goto ddr4
if %next_step%==1 goto ddr5
if %next_step%==2 goto system
if %next_step%==3 goto exit

:ddr4
echo --------------------------------------------------------
echo 安装ddr4的底层...
echo --------------------------------------------------------
tools\fastboot flash oppo_sec firmware-update\oppo_sec.img
tools\fastboot reboot fastboot
tools\fastboot flash bluetooth firmware-update\BTFM.img
tools\fastboot flash DRIVER firmware-update\DRIVER.img
tools\fastboot flash abl firmware-update\abl.img
tools\fastboot flash aop firmware-update\aop.img
tools\fastboot flash engineering_cdt firmware-update\cdt_engineering.img
tools\fastboot flash cmnlib firmware-update\cmnlib.img
tools\fastboot flash cmnlib64 firmware-update\cmnlib64.img
tools\fastboot flash devcfg firmware-update\devcfg.img
tools\fastboot flash apdp firmware-update\dpAP.img
tools\fastboot flash dsp firmware-update\dspso.img
tools\fastboot flash dtbo firmware-update\dtbo.img
tools\fastboot flash hyp firmware-update\hyp.img
tools\fastboot flash keymaster firmware-update\keymaster64.img
tools\fastboot flash modem firmware-update\modem.img
tools\fastboot flash qupfw firmware-update\qupv3fw.img
tools\fastboot flash splash firmware-update\splash.img
tools\fastboot flash mdm_oem_stanvbk firmware-update\static_nvbk.img
tools\fastboot flash storsec firmware-update\storsec.img || echo "此处报错可忽略"
tools\fastboot flash tz firmware-update\tz.img

tools\fastboot flash xbl_config firmware-update\xbl_config_ddr4.img
tools\fastboot flash xbl firmware-update\xbl_ddr4.img
tools\fastboot flash imagefv firmware-update\imagefv_ddr4.img

tools\fastboot flash recovery twrp.img

tools\fastboot flash vbmeta images\vbmeta.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_system images\vbmeta_system.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_vendor images\vbmeta_vendor.img --disable-verity --disable-verification 
cls
echo --------------------------------------------------------
echo "刷入底层完成        你刷的类型是  %id%"  
echo --------------------------------------------------------
pause
cls
goto main

:ddr5
echo --------------------------------------------------------
echo 安装ddr5的底层...
echo --------------------------------------------------------
tools\fastboot flash oppo_sec firmware-update\oppo_sec.img
tools\fastboot reboot fastboot
tools\fastboot flash bluetooth firmware-update\BTFM.img
tools\fastboot flash DRIVER firmware-update\DRIVER.img
tools\fastboot flash abl firmware-update\abl.img
tools\fastboot flash aop firmware-update\aop.img
tools\fastboot flash engineering_cdt firmware-update\cdt_engineering.img
tools\fastboot flash cmnlib firmware-update\cmnlib.img
tools\fastboot flash cmnlib64 firmware-update\cmnlib64.img
tools\fastboot flash devcfg firmware-update\devcfg.img
tools\fastboot flash apdp firmware-update\dpAP.img
tools\fastboot flash dsp firmware-update\dspso.img
tools\fastboot flash dtbo firmware-update\dtbo.img
tools\fastboot flash hyp firmware-update\hyp.img
tools\fastboot flash keymaster firmware-update\keymaster64.img
tools\fastboot flash modem firmware-update\modem.img
tools\fastboot flash qupfw firmware-update\qupv3fw.img
tools\fastboot flash splash firmware-update\splash.img
tools\fastboot flash mdm_oem_stanvbk firmware-update\static_nvbk.img
tools\fastboot flash storsec firmware-update\storsec.img || echo "此处报错可忽略"
tools\fastboot flash tz firmware-update\tz.img

tools\fastboot flash xbl_config firmware-update\xbl_config_ddr5.img
tools\fastboot flash xbl firmware-update\xbl_ddr5.img
tools\fastboot flash imagefv firmware-update\imagefv_ddr5.img


tools\fastboot flash recovery twrp.img

tools\fastboot flash vbmeta images\vbmeta.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_system images\vbmeta_system.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_vendor images\vbmeta_vendor.img --disable-verity --disable-verification 
echo --------------------------------------------------------
echo "刷入底层完成        你刷的类型是  %id%"  
echo --------------------------------------------------------
pause
goto main

:system
echo --------------------------------------------------------
echo 安装系统等操作...
echo ---------------------------------------------------------
echo 清除逻辑分区...
if exist images\super.zst tools\zstd --rm -d images\super.zst -o images\super.img
if exist images\super.img (
    tools\fastboot flash super images\super.img
) else (
    tools\fastboot delete-logical-partition odm
    tools\fastboot delete-logical-partition system
    tools\fastboot delete-logical-partition system_ext
    tools\fastboot delete-logical-partition product
    tools\fastboot delete-logical-partition vendor
    tools\fastboot delete-logical-partition my_carrier
    tools\fastboot delete-logical-partition my_company
    tools\fastboot delete-logical-partition my_engineering
    tools\fastboot delete-logical-partition my_heytap
    tools\fastboot delete-logical-partition my_manifest
    tools\fastboot delete-logical-partition my_preload
    tools\fastboot delete-logical-partition my_product
    tools\fastboot delete-logical-partition my_region
    tools\fastboot delete-logical-partition my_stock
    tools\fastboot delete-logical-partition my_bigball
    tools\fastboot delete-logical-partition odm-cow
    tools\fastboot delete-logical-partition system-cow
    tools\fastboot delete-logical-partition system_ext-cow
    tools\fastboot delete-logical-partition product-cow
    tools\fastboot delete-logical-partition vendor-cow
    tools\fastboot delete-logical-partition my_carrier-cow
    tools\fastboot delete-logical-partition my_company-cow
    tools\fastboot delete-logical-partition my_engineering-cow
    tools\fastboot delete-logical-partition my_heytap-cow
    tools\fastboot delete-logical-partition my_manifest-cow
    tools\fastboot delete-logical-partition my_preload-cow
    tools\fastboot delete-logical-partition my_product-cow
    tools\fastboot delete-logical-partition my_region-cow
    tools\fastboot delete-logical-partition my_stock-cow
    tools\fastboot delete-logical-partition my_bigball-cow
    echo 创建并刷入逻辑分区...
    tools\fastboot create-logical-partition vendor 1
    tools\fastboot flash vendor images\vendor.img
    tools\fastboot create-logical-partition product 1
    tools\fastboot flash product images\product.img
    tools\fastboot create-logical-partition system 1
    tools\fastboot flash system images\system.img
    tools\fastboot create-logical-partition system_ext 1
    tools\fastboot flash system_ext images\system_ext.img
    tools\fastboot create-logical-partition odm 1
    tools\fastboot flash odm images\odm.img
    if exist images\my_bigball.img (
        tools\fastboot create-logical-partition my_bigball 1
        tools\fastboot flash my_bigball images\my_bigball.img
    )
    tools\fastboot create-logical-partition my_carrier 1
    tools\fastboot flash my_carrier images\my_carrier.img
    tools\fastboot create-logical-partition my_company 1
    tools\fastboot flash my_company images\my_company.img
    tools\fastboot create-logical-partition my_engineering 1
    tools\fastboot flash my_engineering images\my_engineering.img
    tools\fastboot create-logical-partition my_heytap 1
    tools\fastboot flash my_heytap images\my_heytap.img
    tools\fastboot create-logical-partition my_manifest 1
    tools\fastboot flash my_manifest images\my_manifest.img
    tools\fastboot create-logical-partition my_preload 1
    tools\fastboot flash my_preload images\my_preload.img
    tools\fastboot create-logical-partition my_product 1
    tools\fastboot flash my_product images\my_product.img
    tools\fastboot create-logical-partition my_region 1
    tools\fastboot flash my_region images\my_region.img
    tools\fastboot create-logical-partition my_stock 1
    tools\fastboot flash my_stock images\my_stock.img
)
tools\fastboot flash boot images\boot.img

tools\fastboot flash vbmeta images\vbmeta.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_system images\vbmeta_system.img --disable-verity --disable-verification 
tools\fastboot flash vbmeta_vendor images\vbmeta_vendor.img --disable-verity --disable-verification
fastboot reboot recovery
echo.正在重启到twrp...
echo --------------------------------------------------------
echo 所有刷入操作完成，请按回车回到主界面。
echo --------------------------------------------------------
pause
cls
goto main

:exit
echo --------------------------------------------------------
echo                                    正在退出...
echo --------------------------------------------------------
exit
