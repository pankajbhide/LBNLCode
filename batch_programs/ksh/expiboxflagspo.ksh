#! /bin/ksh
#==============================================================================
# Installation : Berkeley Lab
#
# Application  : IBOX
#
#                Execute PL/SQL script for exporting recipient information
# Author       : Pankaj Bhide
#
# Module Name  : expiboxflagspo.ksh
#
# Schedule     : Every day
#
# Date written : 09-SEP-16
#
#
# Modification
# History      :  20-NOV-16 Added error trapping logic
#=============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$EXPIBOXFLAGSPO_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f expiboxflagspo.joblog 1>/dev/null 2>>/dev/null


echo '============================================='     > expiboxflagspo.joblog
echo 'Job Log of expiboxflagspo.ksh '                    >> expiboxflagspo.joblog
echo '============================================='     >> expiboxflagspo.joblog
echo 'FLAGS/PO Export Processing started @' `date`       >> expiboxflagspo.joblog




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
    start $MXES_SITE_HOME/sql/expiboxflagspo.sql
    exit sql.sqlcode
SQL_END19

SQL_EXIT0=$?

case "$SQL_EXIT0"
 in
   0)  print 'Preparation of ibox PO Flags export file Completed @'   `date` '- job ended successfully' >> expiboxflagspo.joblog;;
   *)  print 'Preparation of ibox PO Flags export file Terminated @'   `date` '- error exit:' $SQL_EXIT0  >> expiboxflagspo.joblog; exit 1;;
   esac
#
########################
# FTP file to FTP server
########################


scp $MAXIMOFEEDERDIR/Flags.txt           $IBOXUSERID@$IBOXFTPSERVER:inbound/.    1>/dev/null 2>>/dev/null
SCP_EXIT1=$?

scp $MAXIMOFEEDERDIR/lbl_ps2iboxinfo.txt $IBOXUSERID@$IBOXFTPSERVER:inbound/.    1>/dev/null 2>>/dev/null
SCP_EXIT2=$?



SCP_EXIT=$(($SCP_EXIT1+$SCP_EXIT2))

mv expiboxflagspo.joblog       $MXES_SITE_HOME/log/expiboxflagspo.joblog.$FILESUF


exit $SCP_EXIT
