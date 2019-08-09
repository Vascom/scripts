#!/bin/bash

previous_date_file="/tmp/previous_date_file"

remote_date_raw=$(curl -s http://opensource-data.mapswithme.com/regular/weekly/ | \
    grep Russia_Moscow.mwm | awk '{print $3}')
remote_date=$(date -d "$remote_date_raw" +%Y%m%d)
local_date=$(cat "$previous_date_file")

if [ "$remote_date" -gt "$local_date" ]; then
    echo "New date $remote_date" | mutt -x -s "MapsMe updates ready" vascom2@gmail.com
    echo "$remote_date" > "$previous_date_file"
fi
