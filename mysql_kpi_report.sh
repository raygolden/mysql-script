#!/bin/sh
#Name:          mysql_kpi_report.sh
#Usage:         ./mysql_kpi_report.sh
#Description:   analyze mysql’s status and report to us
#Version:       0.1
#Created By:    eugene
. ~/.bash_profile
SENDEMAIL=/data/bin/sendEmail
BASE_DIR=/data
CONF_DIR="$BASE_DIR"/conf
BIN_DIR="$BASE_DIR"/bin
BAKCUP_DIR="$BASE_DIR"/backup
MYSQL_PORT_START=3306
MYSQL_PORT_END=3306
MYSQL_PORT_START_1="$MYSQL_PORT_START"
MAILTO=ray_golden@sina.com
HOST=`hostname | awk -F"." ‘{print $1}’
`
MAIL_FROM=ray_golden@sina.com
MAIL_USER=ray_golden@sina.com
MAIL_PWD=password
REPORT_DATE=`date +"%Y%m%d"`
REPORT="$BAKCUP_DIR"/DailyReport_"$REPORT_DATE".txt
while [ "$MYSQL_PORT_START" -le "$MYSQL_PORT_END" ]
do
  F_PASS="$CONF_DIR"/.mysql_info."$MYSQL_PORT_START"
  if [ -f $F_PASS ] ; then
     . $F_PASS
     if [ "$MYSQL_PORT_START_1" -eq "$MYSQL_PORT_START" ] ; then
        echo “$MYSQL_PORT_START " >> “$REPORT"
     else
       echo -e “\n \n \n \n $MYSQL_PORT_START " >> “$REPORT"
     fi
     $BIN_DIR/mysqlreport --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCK >> $REPORT
  fi
  MYSQL_PORT_START=`expr $MYSQL_PORT_START + 1`
done
if [ -f "$REPORT" ] ; then
   cat "$REPORT" | "$SENDEMAIL" -m -a "$REPORT" -f "$MAIL_FROM" -s smtp.sina.com -t "$MAILTO" -s smtp.sina.com -u "mysql_kpi_report: mysql_"$HOST"" -xu "$MAIL_USER" -xp "$MAIL_PWD"
   if [ $?=0 ] ; then
      rm -f "$REPORT"
   fi
fi
