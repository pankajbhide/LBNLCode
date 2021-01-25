#! /bin/ksh
#==============================================================================
# Installation : Berkeley Lab
# Application  : Space Recharge
#                Execute PL/SQL scripts for Monthly Space Recharge processing
# Author       : Pankaj Bhide
# Module Name  : SP_RECHARGE.KSH
# Schedule     : First day of the month
#==============================================================================
# Maintenance Log:
#
#                 Pankaj 10/17/15 - Changes for MAXIMO 7.6
#==============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/odyssey.env


if [[ "$SP_RECHRG_ENABLE" == "0" ]]
then
  exit 0;
fi


export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

echo 'Job Log of Space Recharge' > ody_joblog
echo '=========================================' >> ody_joblog
echo 'Space Recharge Job started @' `date` >> ody_joblog

#######################################
# Start calculating the space recharge
#######################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${ODY_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/sp_recharge1.sql
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

echo 'Space Recharge calculation completed ' >> ody_joblog


##############################################################
# Now UPDATE FINANCIALPERIODS. MARK IT AS CLOSED.
##############################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END5
${ODY_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/updtperd.sql 'SPA01' $ORGID
    exit sql.sqlcode
SQL_END5

SQL_EXIT2=$?

echo 'FINANCIALPERIODS updated @' `date` >> ody_joblog

echo 'Space Recharge Job completed @' `date` >> ody_joblog

cp ody_joblog $MXES_SITE_HOME/log/ody_joblog.$FILESUF

/usr/ucb/Mail -s "Space Feeder Joblog" $MAIL_REC < ody_joblog

#############################################
# Remove spool files after executing reports
#############################################
rm -f ody_joblog 1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2))

exit $SQL_EXIT
