#!/bin/bash

if [ -z "$1" ]
then
    echo "Please enter file list for download."
    exit 1
else
    if [ -e "$1" ]
    then
        links=`cat "$1"`

        for url in $links
        do
            wget "$url"
        done
    else
        echo "File list $1 not exist."
        exit 1
    fi
fi
