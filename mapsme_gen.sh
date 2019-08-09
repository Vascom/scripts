#!/bin/bash

pl_url_s="https://download.geofabrik.de/"
russia_place="russia/"
russia_central="central-fed-district-latest.osm.pbf"
tunisia_place="africa/"
tunisia="tunisia-latest.osm.pbf"

#Reset color
Color_Off='\e[0m'       # Text Reset
#Colors
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow

ignore=0

if [ -z "$1" ]; then
    echo "Please enter region name:"
    echo "Russia_Moscow"
    echo "Russia_Moscow Oblast_West"
    echo "Russia_Moscow Oblast_East"
    echo "Tunisia"
    exit 1
else
    SOURCE_TC="$1"
fi

if [ "$1" == "check" ]; then
    echo -n "Russia "
    curl -s ${pl_url_s}${russia_place} | grep -m 1 $russia_central \
    | cut -d ">" -f10 | cut -d " " -f1,2
    exit 0
elif [ "$1" == "ignore" ]; then
    ignore=1
    shift
fi

declare -a COUNT
max_count=$#

for i in $(seq 1 $max_count);do
    COUNT[$i]=$1
    shift
done

COUNTRIES=${COUNT[1]}
for i in $(seq 2 $max_count);do
    COUNTRIES=$(echo $COUNTRIES,${COUNT[$i]})
done

pushd ~/mapsme/omim/tools/python
pushd maps_generator/var/etc/
if [ "${COUNT[1]}" == "Tunisia" ]; then
    sed -i "s|.*PLANET_URL.*|PLANET_URL: ${pl_url_s}${tunisia_place}${tunisia}|" map_generator.ini
    sed -i "s|.*PLANET_MD5_URL.*|PLANET_MD5_URL: ${pl_url_s}${tunisia_place}${tunisia}.md5|" map_generator.ini
else
    sed -i "s|.*PLANET_URL.*|PLANET_URL: ${pl_url_s}${russia_place}${russia_central}|" map_generator.ini
    sed -i "s|.*PLANET_MD5_URL.*|PLANET_MD5_URL: ${pl_url_s}${russia_place}${russia_central}.md5|" map_generator.ini
fi
popd

python3 -m maps_generator --countries="$COUNTRIES" --skip="coastline"
# python3 -m maps_generator --countries="$COUNTRIES"
if [ $? -eq 0 -o $ignore -eq 1 ]; then
    popd
    for i in $(seq 1 $max_count);do
        find ~/mapsme/maps_build/ -name "${COUNT[$i]}.mwm" -exec scp {} vpnmercury:/var/www/webdav/mapsme/ \;
    done
    rm -rf ~/mapsme/maps_build/20*
else
    popd
    for i in $(seq 1 $max_count);do
        find ~/mapsme/maps_build/ -name "${COUNT[$i]}.mwm" -delete
    done
    echo -e "${Red}Build failed!${Color_Off}"
    exit 2
fi
