#! /bin/ksh
#==============================================================================
# Installation : Berkeley Lab
#
# Application  : IBOX
#
#                Execute PL/SQL script for importing asset information
# Author       : Pankaj Bhide
#
# Module Name  : impiboxasset.ksh
#
# Schedule     : Every day
#
# Date written : 21-SEP-16
#
#
# Modification
# History      : NOV 20 2016 Pankaj - Added error trapping logic
#=============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$IMPIBOXASSET_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f impiboxasset.joblog 1>/dev/null 2>>/dev/null


echo '============================================='     > impiboxasset.joblog
echo 'Job Log of impiboxasset.ksh '                  >> impiboxasset.joblog
echo '============================================='      >> impiboxasset.joblog
echo 'IBOX Asset Import Processing started @' `date`   >> impiboxasset.joblog


#
###########################
# Get  file from FTP server
###########################

scp $IBOXUSERID@$IBOXFTPSERVER:outbound/Asset_Export.txt     $MAXIMOFEEDERDIR/Asset_Export.txt   1>/dev/null 2>>/dev/null
SCP_EXIT0=$?

case "$SCP_EXIT0"
 in
   0)  print 'Secured copy of assets completed @'   `date` '- job ended successfully' >> impiboxasset.joblog;;
   *)  print 'Secured copy of assets  terminated @'   `date` '- error exit:' $SCP_EXIT0  >> impiboxasset.joblog; exit 1;;
   esac
#


######################################################
# Start processing the contents of  file
######################################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END19
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/impiboxasset.sql
    exit sql.sqlcode
SQL_END19

SQL_EXIT0=$?

case "$SQL_EXIT0"
 in
   0)  print 'Asset import processing Completed @'   `date` '- job ended successfully' >> impiboxasset.joblog;;
   *)  print 'Asset import processing Terminated @'   `date` '- error exit:' $SQL_EXIT0  >> impiboxasset.joblog; exit 1;;
   esac
#


mv impiboxasset.joblog       $MXES_SITE_HOME/log/impiboxasset.joblog.$FILESUF


exit $SQL_EXIT0
