#!/bin/bash

#/etc/mail.rc or ~/.mailrc
#SMTP server for Ecotelecom provider
#set smtp=smtp.ecotelecom.ru

START_DATE=`date`
SENSORS=`sensors`
LOCAL_HOSTNAME=`hostname -s`

echo -e "Компьютер $LOCAL_HOSTNAME запущен $START_DATE\n\n $SENSORS" | mail -s "$LOCAL_HOSTNAME started $START_DATE" vascom2@gmail.com
