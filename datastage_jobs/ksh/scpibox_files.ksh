#! /bin/ksh
######################################################################################
# Project   : LBNL
# Author    : Pankaj Bhide
# Ver 1.0   : Initial Version
# Modified Date: Nov 5, 2019
# Modified By:
# Notes     : This script receives and copies the csv files from/to IBOX FTP server
#            
# Execution : ./scpibox_files.ksh <receive/send> <filename>
#===================================================================================
. /home/dsadm/etl-app01/itbs_shared/fac/dat/ibox.env


#===================================================================================
# Check Script Usage
#===================================================================================

if [[ $# -ne 2 ]]
then
        echo "USAGE: ./scpibox_files.ksh <receive/send> <filename>"
        exit 1
fi

#===================================================================================
# Prepare variables
#===================================================================================
RECEIVE_SEND=$1
FILE_NAME=$2

#data_directory='/home/dsadm/itbs_shared/fac/dat'
data_directory='/home/dsadm/etl-app01/itbs_shared/fac/dat'


export FILESUF   FILESUF=`date '+%y%m%d'`

if [[ $RECEIVE_SEND = "receive" ]] then
    scp $IBOXUSERID@$IBOXFTPSERVER:outbound/$FILE_NAME     $data_directory/.   1>/dev/null 2>>/dev/null
    SCP_EXIT0=$?
fi

if [[ $RECEIVE_SEND = "send" ]] then
    scp $data_directory/$FILE_NAME $IBOXUSERID@$IBOXFTPSERVER:inbound/.   1>/dev/null 2>>/dev/null
    SCP_EXIT0=$?
fi


# Return the combined returned status to the shell

exit $SCP_EXIT

