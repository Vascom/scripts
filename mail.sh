#!/bin/bash

#/etc/mail.rc or ~/.mailrc
#SMTP server for Ecotelecom provider
#set smtp=smtp.ecotelecom.ru

start_stop=1

start_date=`date`
sensors=`sensors`
apc=`apcaccess`
local_hostname=`hostname -s`

STATE_RU=остановлен
STATE_EN=stop

if [ $start_stop == 1 ]
then
    STATE_RU=запущен
    STATE_EN=start
fi

echo -e "Компьютер $local_hostname $STATE_RU $start_date\n\n $sensors\n\n $apc" |
    mail -s "$local_hostname $STATE_EN $start_date" vascom2@gmail.com
