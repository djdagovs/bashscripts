#!/bin/bash

####
# FileSystemCheck Status - fsckStatus
#
#     list fsck status from all disks
#
# author: robert tulke, rt@debian.sh



#disktype_excluded="TYPE=\"LVM2_member\"|TYPE=\"swap\"|TYPE=\"iso9660\""
disktype_excluded=""

p_tune2fs=$(which tune2fs)
p_blkid=$(which blkid)



if [[ $EUID -ne 0 ]]; then

    echo "must be run as root"
    exit 1

fi



check_disk() {


    if [ "$1" = "list_failed_disks" ]; then

        echo

        for i in $($p_blkid |awk -F':' {'print $1'} |sort -n); do

            $p_tune2fs -l $i > /dev/null 2>&1
            rc=$?
            if [ "$rc" == "1" ]; then
                echo "      ${i}"
            fi

        done
    fi


    if [ "$1" == "list_disks" ]; then

        for i in $($p_blkid |awk -F':' {'print $1'} |sort -n); do

            $p_tune2fs -l $i > /dev/null 2>&1
            rc=$?
            if [ ! "$rc" == "1" ]; then
                echo "$i"
            fi

        done
    fi


    if [ "$1" == "status_failed_disk" ]; then

        for i in $($p_blkid |awk -F':' {'print $1'} |sort -n); do

            $p_tune2fs -l $i > /dev/null 2>&1
            rc=$?
            if [ "$rc" == "1" ]; then
                status_failed_disk="1"
            fi

        done
    fi

}



get_mounted_on() {

    mountpoint=$1
    $p_tune2fs -l $mountpoint 2>&1 |awk '/Last mounted on:/ {print $4}' |awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}'
}



get_mount_count() {

    mountpoint=$1
    $p_tune2fs -l $mountpoint 2>&1 |awk '/Mount count:/ {$1=""; $2=""; print $0}' |awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}'
}



get_max_count() {

    mountpoint=$1
    $p_tune2fs -l $mountpoint 2>&1 |awk '/Maximum mount count:/ {print $4}' |awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}'
}



get_check_interval(){

    mountpoint=$1
    $p_tune2fs -l $mountpoint 2>&1 |awk '/Check interval:/ {$1=""; $2=""; print $0}' |awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}'
}



get_last_check() {

    mountpoint=$1
    $p_tune2fs -l $mountpoint 2>&1 |awk '/Last checked:/ {$1=""; $2=""; print $0}' |awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}'
}



main() {

    ## check if bad superblock disks are there
    check_disk status_failed_disk

    if [[ ! -z "$disktype_excluded" || ! -z "$status_failed_disk" ]]; then

        ## count excluded disks
        wc=$(echo ${disktype_excluded} |sed 's/|/ /g' |wc -w)
        echo "$wc disks types were excluded by string: [${disktype_excluded}]"

        ## count failed disks
        wcfd=$(check_disk list_failed_disks |wc -w)
        failed_disks=$(check_disk list_failed_disks)
        echo "$wcfd disks were excluded by failed - bad superblock:"
        echo "${failed_disks}"
        echo

        if [ ! -z "$disktype_excluded" ]; then

            disks=$(check_disk list_disks |egrep -v "${disktype_excluded}" |sort -n)

        else

            disks=$(check_disk list_disks |sort -n)

        fi

    else

        disks=$(check_disk list_disks |sort -n)

    fi

    maxlength=$(for i in $disks; do echo $i |wc -m; done |sort -n |tail -n1)

    column1="$maxlength"    # length    mountpoint
    column2="13"            # length    mount counter
    column3="22"            # length    check intervall
    column4="24"            # length    last check
    column5="20"            # length    mounted on

    printf "%-${column1}s | %-${column2}s | %-${column3}s | %-${column4}s | %-${column5}s\n" Mountpoint Mount\ counter Check\ interval Last\ fsck Last\ mounted\ on
    printf "%-${column1}s | %-${column2}s | %-${column3}s | %-${column4}s | %-${column5}s\n" | tr ' ' -

    for mountpoint in $disks; do

        max_count=$(get_max_count ${mountpoint})
        mount_count=$(get_mount_count ${mountpoint})
        mounted_on=$(get_mounted_on ${mountpoint})
        check_interval=$(get_check_interval ${mountpoint})
        last_check=$(get_last_check ${mountpoint})

        printf "%-${column1}s | %-${column2}s | %-${column3}s | %-${column4}s | %-${column5}s\n" "$mountpoint" "${mount_count}/${max_count}" "$check_interval" "$last_check" "$mounted_on"

    done
}

main
