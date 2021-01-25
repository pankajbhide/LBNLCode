#! /bin/ksh
#===============================================================================
# Installation : Berkeley Lab
# Application  :
#                Execute PL/SQL scripts for Monthly Warehouse Recharge processing
# Author       : Pankaj Bhide
# Module Name  : fsmwarehousefeeder.ksh
# Schedule     : First day of the month
#===============================================================================
# Maintenance Log:
#=============================================================================
# Set environment


export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$FSMWAREHOUSEFEEDER_MTH_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f warehouse_joblog str.csv str.cnt 1>/dev/null 2>>/dev/null

echo '========================================='  > warehouse_joblog
echo 'Job Log of fsmwarehouse_mthend.ksh '     >> warehouse_joblog
echo '========================================='   >> warehouse_joblog
echo 'Warehouse Recharge Calculation started @' `date` >> warehouse_joblog

###########################################
# Start calculating the warehouse recharge
###########################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/fsmwarehouse_feeder_mth01.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'Warehouse Recharege Calculation Completed @'   `date` '- job ended successfully' >> warehouse_joblog;;
   *)  print 'Warehouse Recharge Calculation  Terminated@'   `date` '- error exit:' $SQL_EXIT1  >> warehouse_joblog;;
   esac
#

#############################################
# Remove spool files before executing reports
#############################################
rm -f  warehouse_recharge.lst warehouse_cnt.lst 1>/dev/null 2>>/dev/null

###############################################################################
# Obtain number of records written to  invoice table & spool it to warehouse_cnt.lst
###############################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/fsmwarehouse_feeder_mth04.sql  $ORGID $SITEID
    exit sql.sqlcode
SQL_END2


# If the file does not exist
if [[ ! -a warehouse_cnt.lst ]]
then
   exit 0;
fi

#############################################################
# Exit if there are no records in 'invoice' table
# and report to administrator
#############################################################
REC_CNT=`cat warehouse_cnt.lst`
FL_CNT=`echo $REC_CNT || awk '{print substr($REC_CNT,1,1) }' `
if [[ "$FL_CNT" = "0" ]]
then
   /usr/ucb/Mail -s "Monthly Warehouse Recharge Program" $MAIL_REC < $MXES_SITE_HOME/dat/warehouse_empty1.dat
   cp $MXES_SITE_HOME/dat/warehouse_empty1.dat $MXES_SITE_HOME/log/warehouse_recharge.$FILESUF
   exit 0;
fi

echo 'Warehouse feeder CSV file preparation started @' `date` >> warehouse_joblog

rm -f $MAXIMOFEEDERDIR/str.csv 1>/dev/null 2>>/dev/null

##################################################################
# Now dump the contents of the table into CSV file
# recognized by FMS Feeder
##################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END6
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/format_projfdr.sql $ORGID $SITEID STR
    exit sql.sqlcode
SQL_END6

SQL_EXIT2=$?

#
 case "$SQL_EXIT2"
 in
   0)  print 'Warehouse Feeder CSV file prepration Completed @'   `date` '- job ended successfully' >> warehouse_joblog;;
   *)  print 'Warehouse Feeder CSV file preparation Terminated@'   `date` '- error exit:' $SQL_EXIT2  >> warehouse_joblog;;
   esac
#



############################################################################
# Copy feeder file to xfer directory so that FMS feeder can pickup that file
############################################################################

if [[ "$EXEC_ENV" = "P" ]] then
 cp $MAXIMOFEEDERDIR/str.csv /xfer/fms/prod/feeder/str_csv/str.csv
 cp $MXES_SITE_HOME/dat/express   /xfer/fms/prod/feeder/str_csv/express_csv
fi

cp $MAXIMOFEEDERDIR/str.csv $MXES_SITE_HOME/dat/str.csv.$FILESUF
cp $MAXIMOFEEDERDIR/str.cnt $MXES_SITE_HOME/dat/str.cnt.$FILESUF

echo 'Generation of Warehouse recharge report started @' `date` >> warehouse_joblog

################################################################
# Execute consolidated report for recharge and email to
# administrator
################################################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END3
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/fsmwarehouse_feeder_mth02.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END3

SQL_EXIT=$?

#
 case "$SQL_EXIT"
 in
   0)  print 'Generation of warehouse recharge report Completed @'   `date` '- job ended successfully' >> warehouse_joblog;;
   *)  print 'Generation of warehouse recharge Report Terminated@'   `date` '- error exit:' $SQL_EXIT  >> warehouse_joblog;;
   esac
#


# If the file does not exist
if [[ ! -a warehouse_recharge.lst ]]
then
   exit 0;
fi

/usr/ucb/Mail -s "Monthly warehouse Recharge Report" $MAIL_REC < warehouse_recharge.lst

           
########################################################
# Send the feeder control details to General Accounting
########################################################
if test -r $MXES_SITE_HOME/dat/fac_feeder_mail.dat
then

# Now scan all records in this file and send notification to every person
# listed in that file

for line in `cat $MXES_SITE_HOME/dat/fac_feeder_mail.dat`
do
    EMAIL_ID=`echo $line`
    /usr/ucb/Mail -s "Warehouse Recharge Control Totals" $EMAIL_ID < $MAXIMOFEEDERDIR/str.cnt
done
fi


###########################################################################
# Now update financialperiods table and mark the financialperiod as closed.
###########################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END8
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/updtperd.sql 'STR' $ORGID
    exit sql.sqlcode
SQL_END8

SQL_EXIT4=$?

#
 case "$SQL_EXIT4"
 in
   0)  print 'Updated financialperiods successfully @'   `date` '- job ended successfully' >> warehouse_joblog;;
   *)  print 'Update to financialperiods FAILED @'   `date` '- error exit:' $SQL_EXIT  >> warehouse_joblog;;
   esac
#

/usr/ucb/Mail -s "JOBLOG of warehouse Feeder(month-end)" $MAIL_REC < warehouse_joblog

cp warehouse_recharge.lst $MXES_SITE_HOME/log/warehouse_recharge.$FILESUF
cp warehouse_joblog       $MXES_SITE_HOME/log/warehouse_mthend.$FILESUF

# Remove the temporary files
rm -f  warehouse_joblog warehouse_feedr.sum warehouse_cnt.lst warehouse_recharge.lst  1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2+$SQL_EXIT4))

exit $SQL_EXIT
