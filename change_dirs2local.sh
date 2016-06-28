#!/bin/sh

LOC_GLOB=`basename $0`
case "$LOC_GLOB" in
    change_dirs2local.sh)   CH_FROM="GLOBAL"
                            CH_TO="LOCAL";;
    change_dirs2global.sh)  LOC_GLOB="LOCAL"
                            CH_TO="GLOBAL";;
    *)                      exit 1;;
esac

if [ -z "$1" ]
then
    echo -e "No changes made now."
    echo -e "Please give project \e[31mNAME\e[0m or \e[31mlib\e[0m"
    echo -e "For example:
        \r$0 locata_whole
        \rit will change all *locata_whole/config.makefile files and lib to $CH_TO.
        \rIf given \e[31mlib\e[0m then will changed only lib/config.makefile"
elif [ "$1" = "lib" ]
then
    echo -e "Change dirs to $CH_TO for \e[32mlib\e[0m"
    find lib -name config.makefile -exec sed -i -e 's/= $CH_FROM/= $CH_TO/g' {} \;
else
    echo -e "Change dirs to $CH_TO for \e[32m$1\e[0m config.makefile and \e[32mlib\e[0m"

    find lib -name config.makefile -exec sed -i -e 's/= $CH_FROM/= $CH_TO/g' {} \;
    find . -path "*$1/config.makefile" | xargs sed -i -e 's/= $CH_FROM/= $CH_TO/g'
fi
