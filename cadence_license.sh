#!/bin/sh
# Start Cadence license daemons and specify the debug log file
#
# If editing this file manually, be sure to set values for INSTALL_DIR,
# LICENSE_FILE, and optionally for LOG_FILE and LMGRD_OPTS
#
INSTALL_DIR='/home/cadence/installs/INCISIVE152/'
LICENSE_FILE='/home/cadence/installs/INCISIVE152/share/license/license.dat'
LOG_FILE='/tmp/cadence_lic.log'
LMGRD_OPTS=''
LOG_DIR='/tmp/'

echo
echo "Starting Cadence license daemons"
echo

if [ -r ${INSTALL_DIR}/tools/bin/lmgrd ]; then
  rm -f /tmp/lockcdslmd

  if [ -r ${LOG_FILE} ]; then
    time_stamp=`ls -ol ${LOG_FILE} | awk '{printf "%s.%d.%s\n",$5,$6,$7}'`
    mv ${LOG_FILE} ${LOG_FILE}.$time_stamp
    (echo "	Old debug log files in ${LOG_DIR}:")
    ( ls -l ${LOG_FILE}.* )
  fi

  # so boot can be run in the background and log file can be moved
  # while daemons are running

  ( ${INSTALL_DIR}/tools/bin/lmgrd ${LMGRD_OPTS} -c ${LICENSE_FILE} \
    2>&1 ) | ksh -c "while read line; do echo \"\$line\" >> ${LOG_FILE}; done" &
  sleep 2
else
  echo ""
  echo "Cannot locate the license manager daemon (lmgrd)."
  echo "Please verify that the necessary symbolic link exists before proceeding."
  echo "For more information about licensing utilities, see the 'Cadence"
  echo "License Manager' in CDSDoc."
  echo ""
fi
exit 0
