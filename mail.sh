#!/bin/bash

#/etc/mail.rc or ~/.mailrc
#SMTP server for Ecotelecom provider
#set smtp=smtp.ecotelecom.ru

START_STOP=1

START_DATE=`date`
SENSORS=`sensors`
APC=`apcaccess`
LOCAL_HOSTNAME=`hostname -s`

STATE_RU=остановлен
STATE_EN=stop

if [ $START_STOP == 1 ]
then
    STATE_RU=запущен
    STATE_EN=start
fi

echo -e "Компьютер $LOCAL_HOSTNAME $STATE_RU $START_DATE\n\n $SENSORS\n\n $APC" |
    mail -s "$LOCAL_HOSTNAME $STATE_EN $START_DATE" vascom2@gmail.com
