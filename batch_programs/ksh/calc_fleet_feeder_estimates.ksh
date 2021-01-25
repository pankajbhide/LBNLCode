#! /bin/ksh
#===============================================================================
# Installation : Berkeley Lab
# Application  : Fleet Operations
#                Execute PL/SQL scripts for calculating the Fleet feeder estimates
# Author       : Pankaj Bhide
# Module Name  : calc_fleet_feeder_estimates.ksh
# Schedule     : Daily
#===============================================================================
# Maintenance Log:  1/26/10 Added section to refresh trips tables
#=============================================================================
# Set environment


export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$FLEETFEEDER_ESTIMATES_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f fl_joblog 1>/dev/null 2>>/dev/null

echo '=========================================='  > fl_joblog
echo 'Job Log of calc_fleet_feeder_estimates.ksh '     >>fl_joblog
echo '=========================================='   >> fl_joblog
echo 'Calculation of Fleet feeder estimates started @' `date` >> fl_joblog

#######################################
# Start calculating the fleet recharge
#######################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set echo off
    start $MXES_SITE_HOME/sql/calc_fleet_feeder_estimates.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'Calculation of Fleet Feeder estimates Completed @'   `date` '- job ended successfully' >> fl_joblog;;
   *)  print 'Calculation of Fleet Feeder estimates Terminated@'   `date` '- error exit:' $SQL_EXIT1  >> fl_joblog;;
   esac
#

#################################################
# Now run the program to refrsh the summary tables
# for monthly vehicle usage details
#################################################

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    start $MXES_SITE_HOME/sql/refresh_lbl_mth_vehusage
    exit sql.sqlcode
SQL_END2

SQL_EXIT2=$?

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2))


cp fl_joblog       $MXES_SITE_HOME/log/fleet_feeder_estimates.log.$FILESUF
rm -f fl_joblog 1>/dev/null 2>>/dev/null


exit $SQL_EXIT
