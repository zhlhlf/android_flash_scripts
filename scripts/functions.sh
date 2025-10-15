make_super() {
    echo "start pack super.img..."
    super_dir="$1"
    super_list="$2" #system ...
    super_type=$3   #VAB or AB
    super_slot=$4   #a or b

    sSize=0
    super_group=qti_dynamic_partitions
    argvs="--metadata-size 65536 --super-name super "
    for i in $super_list; do
        image=$(echo "$i" | sed 's/.img//g')
        img_size=$(du -sb "$super_dir/$image.img" | awk '{print $1}')
        if [ "$super_type" = "VAB" ] || [ "$super_type" = "AB" ]; then
            if [ "$super_slot" = "a" ]; then
                argvs+="--partition "$image"_a:none:$img_size:${super_group}_a --image "$image"_a=$super_dir/$image.img --partition "$image"_b:none:0:${super_group}_b "
            elif [ "$super_slot" = "b" ]; then
                argvs+="--partition "$image"_b:none:$img_size:${super_group}_b --image "$image"_b=$super_dir/$image.img --partition "$image"_a:none:0:${super_group}_a "
            fi
        else
            argvs+="--partition "$image":none:$img_size:${super_group} --image "$image"=$super_dir/$image.img "
        fi
        sSize=$(echo "$sSize+$img_size" | bc)
        echo "Super sub-partition [$image] size: [$img_size]"
    done

    #获取手机分区super的大小
    size2=`sgdisk /dev/block/sda --print | grep super | awk '{print $3}'`
    size1=`sgdisk /dev/block/sda --print | grep super | awk '{print $2}'`
    super_size=`echo "($size2 - $size1 + 1) * 4096" | bc`

    echo "super_type: $super_type  slot: $super_slot  set-size: ${super_size} allSize: $sSize"

    argvs+="--device super:$super_size "
    groupSize=$(echo "$super_size-1048576" | bc)
    if [ "$super_type" = "VAB" ] || [ "$super_type" = "AB" ]; then
        argvs+="--metadata-slots 3 --virtual-ab "
        argvs+="--group ${super_group}_a:$groupSize "
        argvs+="--group ${super_group}_b:$groupSize "
    else
        argvs+="--metadata-slots 2 "
        argvs+="--group ${super_group}:$groupSize "
    fi

    if [ -f "$super_dir/super.img" ]; then
        rm -rf $super_dir/super.img
    fi
    argvs+="-F --output $super_dir/super.img"
    if [ ! -d tmp ]; then
        mkdir tmp
    fi
    lpmake $argvs >tmp/make_super.txt 2>&1
    if [ -f "$super_dir/super.img" ]; then
        echo "successfully repack super.img"
    else
        cat tmp/make_super.txt
        error "fail pack super.img"
        exit 1
    fi
}
