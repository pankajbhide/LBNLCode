#! /bin/ksh
#==============================================================================
# Installation : Berkeley Lab
#
# Application  : IBOX
#
#                Execute PL/SQL script for exporting recipient information
# Author       : Pankaj Bhide
#
# Module Name  : exprecipient.ksh
#
# Schedule     : Every day
#
# Date written : 07-SEP-16
#
#
# Modification
# History      :  20-NOV-16 Error trapping logic added.
#=============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$EXPIBOXRECIPIENT_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f expiboxrecipient.joblog 1>/dev/null 2>>/dev/null


echo '============================================='     > expiboxrecipient.joblog
echo 'Job Log of expiboxrecipient.ksh '                  >> expiboxrecipient.joblog
echo '============================================='      >> expiboxrecipient.joblog
echo 'Recipient Export Processing started @' `date`   >> expiboxrecipient.joblog



######################################################
# Start preparing file
######################################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END19
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/expiboxrecipient.sql
    exit sql.sqlcode
SQL_END19

SQL_EXIT0=$?

case "$SQL_EXIT0"
 in
   0)  print 'Preparation of ibox recipient export file Completed @'   `date` '- job ended successfully' >> expiboxrecipient.joblog;;
   *)  print 'Preparation of ibox recipient export file Terminated @'   `date` '- error exit:' $SQL_EXIT0  >> expiboxrecipient.joblog; exit 1;;
   esac
#
########################
# FTP file to FTP server
########################

scp $MAXIMOFEEDERDIR/Recipient.txt $IBOXUSERID@$IBOXFTPSERVER:inbound/.   1>/dev/null 2>>/dev/null

SCP_EXIT=$?

TOT_EXIT=$(($SQL_EXIT0+$SCP_EXIT))

mv expiboxrecipient.joblog       $MXES_SITE_HOME/log/expiboxrecipeient.joblog.$FILESUF


exit $TOT_EXIT
