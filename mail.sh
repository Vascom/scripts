#!/bin/bash

START_DATE=`date`
echo "Компьютер solar запущен $START_DATE" | mail -s "solar started $START_DATE" vascom2@gmail.com
