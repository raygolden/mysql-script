#! /bin/bash

######################################
# Get MySQL option status with MySQL machine 
# Create by Heyf 
# Created at : 2010.04.29
# 
#
#
# The reslut of program will write to  $CONF_FILE
# Example : 
#   rollbackcommit
#   dml
#   innodbio
#   qps
#   ioutil
#   iorwkb
#   slaveio
#   slavesql
#   slavelag
#   innodb_bufsize
#   myisam_keysize
#   trans_isolation
#   char_server
#   char_client
#   char_conn
#   sesscnt
#   session
#   load
#   role
######################################
###### Check parameters 

usage ()
{
cat <<EOF
Usage: $0 [OPTIONS]
  --port=3306                      MySQL Port ,Defalt 3306
  --outfile=/tmp/mysql3306.start   OutPut result to file  
  --vip=10.2.334.252               
  --key=qps,load,iorwkb...         What you want to Check. separated with ","
          Key List: $ALL_KEY  
  
If no "--ip" specified,Program will get first ip in result of  IPCONFIG .
All other options are passed to the program.

EOF
exit 1

}

for Parms in $*
  do
    Pram=$1
    Val=`echo "$Pram" | sed -e "s;--[^=]*=;;"`

    case "$Pram" in 
       --port=*)
         MY_PORT=$Val
       ;;
       --outfile=*)
         MY_OUTFILE=$Val
       ;;
       --vip=*)
         MY_VIP=$Val
       ;;
       --key=*)
         MY_KEY=$Val
       ;;       
       *)
       usage
       exit 1
       ;;
    esac
    shift
done

#####  Variables Define -- Begin

[ -z ~/.bash_profile ] && . ~/.bash_profile 

if [ -z "$MY_PORT" ] ; then
  MY_PORT=3306
fi

CONF_DIR=/home/mysqldata/conf
PASS_FILE="$CONF_DIR"/.mysql_info_sa."$MY_PORT"

if [ -f "$PASS_FILE" ] ; then
   . "$PASS_FILE"
else
  echo "$PASS_FILE IS NOT EXISTS!"
  exit
fi

MY_USER="$MYSQL_USER"
MY_PASSWD="$MYSQL_PASSWORD"
MY_SOCKET="$MYSQL_SOCK"
#MY_HOST=
MY_DATABASE=
ALL_KEY=rollbackcommit,dml,innodbio,qps,ioutil,iorwkb,slaveio,slavesql,slavelag,innodb_bufsize,myisam_keysize,trans_isolation,char_server,char_client,char_conn,sesscnt,session,load,role,

MYADMIN=$(which mysqladmin)
MYSQL=$(which mysql)


[ -z "$MY_PASSWD" ] ||  MY_PASSWD="-p"${MY_PASSWD} 

#####  Variables Define -- End

######################################### Funtions Begin
	
getstat_mysql()
{
# Get status of MySQL

if [ -z "$MYSQL" ] ; then 
	if [ -x /usr/bin/mysql ] ; then 
		MYSQL=/usr/bin/mysql
	else 
	  echo "no_cmd_mysql." 
    return 1 
  fi
fi

 #$MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -e "EXIT"  > /dev/null
 
 $MYSQL -u$MY_USER  $MY_PASSWD -S $MY_SOCKET  -e "EXIT"  > /dev/null
 
 if [ $? -ne 0 ]  ; then
        echo "MySQL_error!"
        return 2
 fi
return 0
}

getstat_mysqladmin()
{
# Get status of MySQL

if [ -z "$MYADMIN" ] ; then 
	  echo "no_cmd_mysqladmin." 
    return 1 
fi
 
return 0
}

getstat_Questions()
{ 
  # Get status of  Questions between 3 sec.
  getstat_mysql
  if [ $? -ne 0 ] ;then
   echo "NO_MYSQL"
   return 1
  fi

  local _var1=Questions
  
  if [ $VERSION_FLAG -eq 1 ] ; then 
  	# Mysql version = 4.x
    #local _var1stat1=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "show status like 'Questions%' " | awk '{print $2}' )
    local _var1stat1=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "show status like 'Questions%' " | awk '{print $2}' )
    
  else
    #local _var1stat1=$($MYSQL -u$MY_USER -h$MY_HOST -p$MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL STATUS LIKE  'Questions%' " | awk '{print $2}' )
    local _var1stat1=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL STATUS LIKE  'Questions%' " | awk '{print $2}' )
  fi
   
  sleep 3 

  if [ $VERSION_FLAG -eq 1 ] ; then 
  	# Mysql version = 4.x
    #local _var1stat2=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "show status like 'Questions%' " | awk '{print $2}' )
    local _var1stat2=$($MYSQL -u$MY_USER  $MY_PASSWD -S $MY_SOCKET -N -s -e "show status like 'Questions%' " | awk '{print $2}' )
  else
    #local _var1stat2=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL STATUS LIKE  'Questions%' " | awk '{print $2}' )
    local _var1stat2=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL STATUS LIKE  'Questions%' " | awk '{print $2}' )
  fi
   
  local _stat1=$(echo "$_var1stat1,$_var1stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
   
  echo $_stat1
  
  return 0
}

getstat_slaveio()
{
# Get Slave_IO_thread status of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
  
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "show slave status \G" | grep Slave_IO_Running | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "show slave status \G" | grep Slave_IO_Running | awk {'print $NF'} )

if [ -z "${_stat}" ] ; then
  _stat="NULL"
fi
echo $_stat
return 0
}

getstat_slavesql()
{
# Get Slave_SQL_thread status of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
  
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "show slave status \G" | grep Slave_SQL_Running | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "show slave status \G" | grep Slave_SQL_Running | awk {'print $NF'} )

if [ -z "${_stat}" ] ; then
  _stat="NULL"
fi
echo $_stat
return 0
}

getstat_slavelag()
{
# Get Slave_lag of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
  
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "show slave status \G" | grep Seconds_Behind_Master | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "show slave status \G" | grep Seconds_Behind_Master | awk {'print $NF'} )

if [ -z "${_stat}" ] ; then
  _stat="NULL"
fi
echo $_stat
return 0
}
 
getstat_innodb_bufsize()
{
# Get Innodb innodb_buffer_pool_size of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_myisam_keysize()
{
# Get Myisam key_buffer_size of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'key_buffer_size'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'key_buffer_size'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_trans_isolation()
{
# Get transaction_isolation of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'tx_isolation'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'tx_isolation'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_char_server()
{
# Get Character set of server of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_server'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_server'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_char_client()
{
# Get Character set of client of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
  
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_client'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_client'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_char_conn()
{
# Get Character set of connection of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_client'" | awk {'print $NF'} )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW GLOBAL VARIABLES LIKE 'character_set_client'" | awk {'print $NF'} )

echo $_stat
return 0
}

getstat_sesscnt()
{
# Get all connection of MySQL
  getstat_mysql
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQL"
    return 1
  fi
#local _stat=$($MYSQL -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT -N -s -e "SHOW PROCESSLIST;" | wc -l )
local _stat=$($MYSQL -u$MY_USER $MY_PASSWD -S $MY_SOCKET -N -s -e "SHOW PROCESSLIST;" | wc -l )

echo $_stat
return 0
}


getstat_session()
{ 
  # Get status of  active_session/total_session
  local _stat1
  local _stat2
  local _var
  local _result
  local _tmpfile=/tmp/stat_sesscnt_$$.tmp

  getstat_mysqladmin
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQLADMIN"
    return 1
  fi

  #$MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT PROCESSLIST | grep "^|" | grep -v "Command"  > $_tmpfile
  $MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET PROCESSLIST | grep "^|" | grep -v "Command"  > $_tmpfile
  
  _var=active_session
  _stat1=$(cat $_tmpfile | grep -v "Sleep" | wc -l )

  _var=total_session
  _stat2=$(cat $_tmpfile | wc -l )
  
  echo ${_stat1},${_stat2} 
  
  \rm -f $_tmpfile
  return 0
}


getstat_load()
{
# Get load of Os
local _stat=$(w |  head -1 | awk -F ":" '{print $NF}' | tr -d ' ' )
echo ${_stat}
return 0
}

getstat_role()
{
#### Get Role : MASTER/SLAVE
# Please Think about :VIP , Qps , Slave_io="" , number of processlist 

local REMOTE_SLAVE_IO=$(getstat_slaveio)
local REMOTE_SLAVE_SQL=$(getstat_slavesql)

if [ -z "$MY_VIP" ] ; then

	# There is no vip .
		
	if [  "$REMOTE_SLAVE_IO" = "NULL"  -a  "$REMOTE_SLAVE_SQL" = "NULL"  ] ; then

    #  There is no slave processs .
      echo "MASTER"	
     
  else

  	#  Running with slave process ,check processlist count >= 10 
  	local REMOTE_SESS_CNT=$(getstat_sesscnt)
  	  if [ $REMOTE_SESS_CNT -ge $MAX_PROC_CNT ] ; then
	      echo "MASTER"	
	    else 
	  	  echo "SLAVE"
	  	fi
  fi
	
else

	# check with a vip
	 
    local VIP_CNT=$( /sbin/ifconfig | grep "$MY_VIP " | wc -l ) 

	  if [ $VIP_CNT	-ne 1 ] ; then
	    echo "SLAVE"
	  else
	  	echo "MASTER"	
	  fi
	
fi

return 0

}


getstat_rollbackcommit()
{ 
  # Get status of  rollback/commit

  getstat_mysqladmin
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQLADMIN"
    return 1
  fi
  
  local _var1=Com_commit
  local _var2=Com_rollback
  
  #local _var1stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local _var2stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  
  local _var1stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local _var2stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')

  sleep 3 

  #local  _var1stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local  _var2stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  
  local  _var1stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local  _var2stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  
  local _stat1=$(echo "$_var1stat1,$_var1stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat2=$(echo "$_var2stat1,$_var2stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  
#  local _result=${_result}${_var1}"="${_stat1}"&"
#        _result=${_result}${_var2}"="${_stat2}"&"
    
  echo ${_stat2},${_stat1}
  
  return 0
}

getstat_dml()
{ 
  #  Get status of  delete/insert/select/update

  getstat_mysqladmin
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQLADMIN"
    return 1
  fi
     
  local _var1=Innodb_rows_deleted
  local _var2=Innodb_rows_inserted
  local _var3=Innodb_rows_read
  local _var4=Innodb_rows_updated
  
  #local _var1stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local _var2stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  #local _var3stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  #local _var4stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var4" " | head -1 | awk '{print $4}')
  
  local _var1stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local _var2stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  local _var3stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  local _var4stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var4" " | head -1 | awk '{print $4}')
 
  sleep 3

  #local _var1stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local _var2stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  #local _var3stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  #local _var4stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var4" " | head -1 | awk '{print $4}')
  
  local _var1stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local _var2stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  local _var3stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  local _var4stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var4" " | head -1 | awk '{print $4}')
  
  local _stat1=$(echo "$_var1stat1,$_var1stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat2=$(echo "$_var2stat1,$_var2stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat3=$(echo "$_var3stat1,$_var3stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat4=$(echo "$_var4stat1,$_var4stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
    
#  local _result=${_result}${_var1}"="${_stat1}"&"
#        _result=${_result}${_var2}"="${_stat2}"&"
#        _result=${_result}${_var3}"="${_stat3}"&"
#        _result=${_result}${_var4}"="${_stat4}"&"
                        
#  echo $(echo $_result | sed -e 's/\&$//' )  
  echo ${_stat2},${_stat1},${_stat4},${_stat3}
  return 0
}


getstat_innodbio()
{ 
  # Get status of  Get status of  Innodb_buffer_pool_read_requests 
  #                                        /Innodb_data_reads/Innodb_data_writes

  getstat_mysqladmin
  if [ $? -ne 0 ] ;then
    echo "NO_MYSQLADMIN"
    return 1
  fi
    
  local _var1=Innodb_buffer_pool_read_requests
  local _var2=Innodb_data_reads
  local _var3=Innodb_data_writes
 
  #local _var1stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local _var2stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  #local _var3stat1=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  
  local _var1stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local _var2stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  local _var3stat1=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var3" " | head -1 | awk '{print $4}')
 
   sleep 3
  #local _var1stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  #local _var2stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  #local _var3stat2=$($MYADMIN -u$MY_USER -h$MY_HOST $MY_PASSWD -P$MY_PORT extended-status | grep $_var3" " | head -1 | awk '{print $4}')
  
  local _var1stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var1" " | head -1 | awk '{print $4}')
  local _var2stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var2" " | head -1 | awk '{print $4}')
  local _var3stat2=$($MYADMIN -u$MY_USER $MY_PASSWD -S $MY_SOCKET extended-status | grep $_var3" " | head -1 | awk '{print $4}')
   
  local _stat1=$(echo "$_var1stat1,$_var1stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat2=$(echo "$_var2stat1,$_var2stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
  local _stat3=$(echo "$_var3stat1,$_var3stat2" | awk -F "," '{total=($2-$1)/3}{printf "%d",total}')    
     
#  local _result=${_result}${_var1}"="${_stat1}"&"
#        _result=${_result}${_var2}"="${_stat2}"&"
#        _result=${_result}${_var3}"="${_stat3}"&"
#         
#  echo $(echo $_result | sed -e 's/\&$//' )
   echo ${_stat1},${_stat2},${_stat3}
  return 0
}

getstat_ioutil()
{ 
   # Get status of  ioutil.
  local _tmpfile=/tmp/stat__ioutil_$$.tmp
  local IOSTAT
  local _cnttime=4
  local DISKS
  
  IOSTAT=$(which iostat)
  if [ "$?" != 0 ] ; then
    yum install -y sysstat.x86_64
    echo "test"
  fi 
  
  if [ -z ${IOSTAT} ] ;  then 
  	 echo "iostat_error"
  	 return 1
  fi
  
  $IOSTAT -x -k 1 $_cnttime > $_tmpfile
  
  local diskcnt=$(echo $(cat $_tmpfile | wc -l),${_cnttime} | awk -F "," '{total=($1-2)/$2+2}{printf "%d",total}')
  sed -i 1,${diskcnt}'d' $_tmpfile

  MAXAVG=0

  for DISKS in $(/sbin/fdisk -l | grep "^Disk" |awk -F ":" '{print $1}' | awk -F "/" '{print $NF}' )
  do
    MAXAVG_TMP=$(grep "${DISKS} "  $_tmpfile | awk '{ if( $NF != "0.00" ) {total+=$NF;cnt+=1;printf "%f\n", total/cnt}}' | tail -1)
    MAXAVG=$(echo $MAXAVG $MAXAVG_TMP | awk '{if ($2 > $1) {print $2} else {print $1} }' )
  done

  _stat=$MAXAVG
  _var=ioutil
  _result=${_result}${_var}"="${_stat}"&"

#  echo $(echo $_result | sed -e 's/\&$//' )
  echo  ${_stat} 
  
  \rm -f $_tmpfile
  return 0
  
}

getstat_iorwkb()
{ 
   # Get status of  io rKB/s wKB/s .
  local _tmpfile=/tmp/stat_iorwkb_$$.tmp
  local IOSTAT
  local _cnttime=4
  local DISKS
  local _stat1 
  local _stat2
   
  IOSTAT=$(which iostat)

  if [ -z ${IOSTAT} ] ;  then 
  	 echo "iostat_error"
  	 return 1
  fi
  
  $IOSTAT -k 1 $_cnttime > $_tmpfile
  
  local diskcnt=$(echo $(cat $_tmpfile | wc -l),${_cnttime} | awk -F "," '{total=($1-2)/$2+2}{printf "%d",total}')
  sed -i 1,${diskcnt}'d' $_tmpfile

  local RKB_MAXAVG=0
  local WKB_MAXAVG=0
  
  for DISKS in $(/sbin/fdisk -l | grep "^Disk" |awk -F ":" '{print $1}' | awk -F "/" '{print $NF}' )
  do
    RKB_MAXAVG_TMP=$(grep "${DISKS} "  $_tmpfile | awk '{ if( $3 != "0.00" ) {total+=$3;cnt+=1;printf "%f\n", total/cnt}}' | tail -1)
    RKB_MAXAVG=$(echo $RKB_MAXAVG $RKB_MAXAVG_TMP | awk '{if ($2 > $1) {print $2} else {print $1} }' )
    
    WKB_MAXAVG_TMP=$(grep "${DISKS} "  $_tmpfile | awk '{ if( $4 != "0.00" ) {total+=$4;cnt+=1;printf "%f\n", total/cnt}}' | tail -1)
    WKB_MAXAVG=$(echo $WKB_MAXAVG $WKB_MAXAVG_TMP | awk '{if ($2 > $1) {print $2} else {print $1} }' )
  done

  _stat1=$RKB_MAXAVG
  _var=rkb
  _result=${_result}${_var}"="${_stat}"&"

  _stat=$WKB_MAXAVG
  _var=wkb
  _result=${_result}${_var}"="${_stat}"&"
  
#  echo $(echo $_result | sed -e 's/\&$//' )
  echo ${RKB_MAXAVG},${WKB_MAXAVG}
    
  \rm -f $_tmpfile
  return 0
  
}

getvalue()
{

# Get values of key
 local _key=$1
 case "${_key}" in 
   'rollbackcommit')
     RESULT="ROLLBACK/COMMIT:"$(getstat_rollbackcommit)
   ;;
   'dml')
     RESULT="DML(I/D/U/S):"$(getstat_dml)
   ;;
   'innodbio')
     RESULT="INNODBIO(Pool_read_qps/reads/writes):"$(getstat_innodbio)
   ;;
   'qps')
     RESULT="QPS:"$(getstat_Questions)
   ;;
   'ioutil')
     RESULT="IOUTIL:"$(getstat_ioutil)
   ;;   
   'iorwkb')
     RESULT="OS_IO(R/W):"$(getstat_iorwkb)
   ;; 
   'slaveio')
     RESULT="SLAVE_IO:"$(getstat_slaveio)
   ;; 
   'slavesql')
     RESULT="SLAVE_SQL:"$(getstat_slavesql)
   ;;
   'slavelag')
     RESULT="SLAVE_LAG:"$(getstat_slavelag)
   ;;
   'innodb_bufsize')
     RESULT="INNODB_BUFSIZE:"$(getstat_innodb_bufsize)
   ;;
   'myisam_keysize')
     RESULT="MYISAM_KEYSIZE:"$(getstat_myisam_keysize)
   ;;
   'trans_isolation')
     RESULT="TX_ISOLATION:"$(getstat_trans_isolation)
   ;;
   'char_server')
     RESULT="CHARSET_SERVER:"$(getstat_char_server)
   ;;
   'char_client')
     RESULT="CHARSET_Client:"$(getstat_char_client)
   ;;
   'char_conn')
     RESULT="CHARSET_Conn:"$(getstat_char_conn)
   ;;
   'sesscnt')
     RESULT="SESSION(ALL):"$(getstat_sesscnt)
   ;;
   'session')
     RESULT="SESSION(ACTIVE/ALL):"$(getstat_session)
   ;;
   'load')
     RESULT="LOAD:"$(getstat_load)
   ;;
   'role')
     RESULT="ROLE:"$(getstat_role)
   ;;
   *)
    echo "${_key}:No_Such_Key"
   ;;
esac

echo $RESULT
}

 

######################################### Funtions End 

#### Main -- Begin 

if [ -z "$MY_HOST" ] ; then
  MY_HOST=`/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk {'print $1'} | head -1`
fi

if [ -z "$MY_PORT" ] ; then 
   MY_PORT=3306
fi 

if [ -z "$MY_KEY" ] ; then 
   MY_KEY=${ALL_KEY}
fi 

KEYLIST=$(echo ${MY_KEY} | tr -d ' ' | sed 's/,/ /g' )

CURRDATE=`date +%F`
MAX_PROC_CNT=10

#### Get Mysql Version 
# if verion = 4.X , VERSION_FLAG=1
VERSION_FLAG=$($MYSQL --version | grep "Distrib 4." | wc -l)
[ -z "${VERSION_FLAG}" ] && VERSION_FLAG=0


#### Start to Loop 
for KEY in $KEYLIST
do
	echo $(getvalue $KEY)
done

exit 0

#### Main -- End