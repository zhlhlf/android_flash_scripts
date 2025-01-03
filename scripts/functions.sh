
make_super(){
    echo "Packing super.img"
    super_size=$1 
    super_dir="$2"
    super_list="$3" #system ...
    super_type=$4  #VAB or AB
    super_slot=$5  #a or b
    
    sSize=0
    super_group=qti_dynamic_partitions
    argvs="--metadata-size 65536 --super-name super "
    for i in $super_list; do
        image=$(echo "$i" | sed 's/.img//g')
        img_size=$(du -sb $super_dir/$image.img | tr -cd 0-9)
        if [ "$super_type" = "VAB" ] || [ "$super_type" = "AB" ];then
            if [ "$super_slot" = "a" ];then    
          	  argvs+="--partition "$image"_a:none:$img_size:${super_group}_a --image "$image"_a=$super_dir/$image.img --partition "$image"_b:none:0:${super_group}_b "
            elif [ "$super_slot" = "b" ];then    
          	  argvs+="--partition "$image"_b:none:$img_size:${super_group}_b --image "$image"_b=$super_dir/$image.img --partition "$image"_a:none:0:${super_group}_a "
            fi
        else
            argvs+="--partition "$image":none:$img_size:${super_group} --image "$image"=$super_dir/$image.img "
        fi
        sSize=$((sSize + img_size))
        echo "Super sub-partition [$image] size: [$img_size]"
    done

    argvs+="--device super:$super_size "
    if [ "$super_type" = "VAB" ] || [ "$super_type" = "AB" ];then
        argvs+="--metadata-slots 3 "
        argvs+="--group ${super_group}_a:$super_size "
        argvs+="--group ${super_group}_b:$super_size "
    else
        argvs+="--metadata-slots 2 "
        argvs+="--group ${super_group}:$super_size "
    fi
    if [ "$super_type" = "VAB" ];then
    	argvs+="--virtual-ab "
    fi
    if [ -f "$super_dir/super.img" ];then
      rm -rf $super_dir/super.img
    fi
    echo "设置的super镜像大小为: ${super_size}"
    echo "所有要打包为super镜像和需要大小为: $sSize"
    argvs+="-F --output $super_dir/super.img"
    scripts/lpmake $argvs > error.txt 2>&1
    if [ -f "$super_dir/super.img" ];then
        echo "成功打包 super.img"
    else
        cat error.txt
        echo "失败打包 super.img"
    fi
}