#!/bin/bash

####
# Author: Robert Tulke, rt@debian.sh
#
# this will compress all jpegs under a folder
# usage: compress_all_jpegs.sh ./mypictures/


FOLDER=$1

## don't start as root
if [ $(whoami) != root ]; then
    echo "run as root only"
    echo
    exit 1
fi


## if no param
if [ -z "$FOLDER" ]; then
    echo "Usage: "
    echo "  ./$(basename $0) <folder>   optimze jpegs in a folder"
    echo
    exit 1
fi


## folder exists?
if [ ! -f "$FOLDER" ]; then
    echo "Directory: ${FOLDER}, not found."
    echo
    exit 1
fi


for i in $(find $1 -iname *_web.jp*g -type f); do
    stamp=$(stat --format '%y %n' $i);
    filedate=$(echo $stamp |awk {'print $1'})
    jpegoptim -o --strip-all $i
    touch -a -m -d $filedate $i
done
exit 0
