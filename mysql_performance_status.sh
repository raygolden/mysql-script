#!/bin/sh

#Author:      Eugene
#Description: every N minutes to get mysql status's value and import to database
#Example:     ./mysql_performance_status.sh --space-of-time=5
#WebSite:mysqlops
#weibo:www.weibo.com/mysqlops
#Create_Time: 2011-09-27 16:00:00
#ALter_Time : 2011-10-11 18:00:00

BASE_DIR='/data'
STATUS_DIR='/data/backup'

MYSQL_PORT_START=3306
MYSQL_PORT_END=3306
DB_NAME=mysql

Curdatetime=`date +%Y%m%d%H%M%S`
Curdate=`date +%Y%m%d`
HOST_IP=`/sbin/ifconfig | grep "inet" | awk -F: '{print $1}' | awk {'print $2'} | tail -2|head -1`

VARIABLES=(Connections Queries Questions Uptime Com_insert Com_insert_select Com_delete Com_delete_multi Com_select Com_update Com_update_multi Com_rollback Com_commit Slow_queries Sort_range Sort_rows Sort_scan Qcache_free_blocks Qcache_free_memory Qcache_hits Qcache_inserts Qcache_lowmem_prunes Qcache_not_cached Qcache_queries_in_cache Key_blocks_used Key_blocks_unused Key_read_requests Key_reads Key_write_requests Key_writes Max_used_connections Bytes_sent Bytes_received Aborted_connects Created_tmp_files Created_tmp_disk_tables Created_tmp_tables Innodb_buffer_pool_read_ahead_rnd Innodb_buffer_pool_read_ahead_seq Innodb_buffer_pool_read_requests Innodb_buffer_pool_reads Innodb_buffer_pool_wait_free Innodb_buffer_pool_write_requests Innodb_rows_deleted Innodb_rows_inserted Innodb_rows_read Innodb_rows_updated)

NOT_DIFF_VARIABLES=(\'Max_used_connections\',\'Qcache_free_memory\',\'Qcache_free_blocks\')

if [ ! -d "$STATUS_DIR" ] ; then
   mkdir -p "$STATUS_DIR"
   chown -R mysql:mysql "$STATUS_DIR"
fi


INPUT_DATA=$1
usage ()
{
cat <<EOF
Usage: $0 [OPTIONS]
  --space-of-time=N        every N minutes to get mysql status's value,For example: --space-of-time=5;

EOF
exit 1
}

case "${INPUT_DATA}" in
     --space-of-time=*)
       SPCE_TIME=`echo "$INPUT_DATA" | sed -e "s;--[^=]*=;;"`
       if [ -z "$SPCE_TIME" ] ; then
          usage
       fi
     ;;
     *) 
       usage
     ;;
esac
shift

SPCE_TIME=`expr $SPCE_TIME + 1`


while [ "$MYSQL_PORT_START" -le "$MYSQL_PORT_END" ]
do
#induct MySQL's USERNAME AND PASSWORD
  F_PASS="$BASE_DIR"/conf/.mysql_info."$MYSQL_PORT_START"
  
  if [ -f $F_PASS ] ; then
     . $F_PASS
     
     if [ 3306  -eq "$MYSQL_PORT_START"  ] ; then
        MY_USER=$MYSQL_USER
        MY_PASSWORD=$MYSQL_PASSWORD
        MY_SOCK=$MYSQL_SOCK
     fi
     
    MY_STATUS="$STATUS_DIR"/status_"$MYSQL_PORT_START".txt
     
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD --socket=$MYSQL_SOCK -e "SHOW  GLOBAL STATUS;">"$MY_STATUS"
    
    #add ip address to text
    sed -i "s/$/\t"$HOST_IP" /" "$MY_STATUS"
    
    #add port to text
    sed -i "s/$/\t"$MYSQL_PORT_START" /" "$MY_STATUS"
    
    #UPTIME_VALUE=`cat "$MY_STATUS" | grep "Uptime" | awk '{print $2}'`
    
    if [ -f "$MY_STATUS".tmp ] ; then
       rm -f "$MY_STATUS".tmp
    fi
    
    for var in ${VARIABLES[@]}
    do
      cat $MY_STATUS | grep -w "$var" >> "$MY_STATUS".tmp
    done
    
    rm -f "$MY_STATUS"
    cat "$MY_STATUS".tmp > "$MY_STATUS"
    rm -f "$MY_STATUS".tmp
    
    strSQL="LOAD DATA INFILE '$MY_STATUS' INTO TABLE performance_tmp(statu_item,total_num,host_ip,host_port);";
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "DELETE FROM performance_tmp WHERE host_ip='"$HOST_IP"' AND host_port="$MYSQL_PORT_START";"
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "$strSQL"
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "UPDATE performance_tmp SET CreateDate=DATE_FORMAT("$Curdatetime",'%Y-%m-%d %H:%i:%s') WHERE host_ip='"$HOST_IP"' AND host_port="$MYSQL_PORT_START";"
    
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "INSERT INTO performance_innodb(statu_item,total_num,host_ip,host_port,CreateDate) SELECT T.statu_item,T.total_num-L.total_num AS CurNum,T.host_ip,T.host_port,T.CreateDate FROM performance_tmp T INNER JOIN performance_innodb_log L ON T.statu_item=L.statu_item WHERE L.CreateDate >=DATE_ADD(T.CreateDate,INTERVAL -"$SPCE_TIME" MINUTE) AND L.CreateDate <=T.CreateDate AND L.host_ip='"$HOST_IP"' AND L.host_port="$MYSQL_PORT_START" AND T.host_ip='"$HOST_IP"' AND T.host_port="$MYSQL_PORT_START" AND T.statu_item NOT IN ("$NOT_DIFF_VARIABLES");"
    
    #Don't need computer
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "INSERT INTO performance_innodb(statu_item,total_num,host_ip,host_port,CreateDate) SELECT T.statu_item,T.total_num,T.host_ip,T.host_port,T.CreateDate FROM performance_tmp T WHERE T.host_ip='"$HOST_IP"' AND T.host_port='"$MYSQL_PORT_START"' AND T.statu_item  IN ("$NOT_DIFF_VARIABLES");"
    
    mysql -u$MY_USER -p$MY_PASSWORD --socket=$MY_SOCK -D "$DB_NAME" -e "INSERT INTO performance_innodb_log(statu_item,total_num,host_ip,host_port,CreateDate) SELECT statu_item,total_num,host_ip,host_port,CreateDate FROM performance_tmp WHERE host_ip='"$HOST_IP"' AND host_port="$MYSQL_PORT_START";"
  fi
  
  MYSQL_PORT_START=`expr $MYSQL_PORT_START + 1`
done
