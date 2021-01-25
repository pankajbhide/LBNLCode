#! /bin/ksh
#===============================================================================
# Installation : Berkeley Lab
# Application  : Fleet Operations
#                Execute PL/SQL scripts for Monthly Fleet Recharge processing
# Author       : Pankaj Bhide
# Module Name  : fleetfeeder_mth.ksh
# Schedule     : First day of the month
#===============================================================================
# Maintenance Log:
#=============================================================================
# Set environment


export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$FSMFLEETFEEDER_MTH_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f fl_joblog 1>/dev/null 2>>/dev/null

echo '========================================='  > fl_joblog
echo 'Job Log of fl_mthend.ksh '     >>fl_joblog
echo '========================================='   >> fl_joblog
echo 'Fleet Recharge Calculation started @' `date` >> fl_joblog

#######################################
# Start calculating the fleet recharge
#######################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/fsmfleet_feeder_mth01.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'Fleet Recharege Calculation Completed @'   `date` '- job ended successfully' >> fl_joblog;;
   *)  print 'Fleet Recharge Calculation  Terminated@'   `date` '- error exit:' $SQL_EXIT1  >> fl_joblog;;
   esac
#

#############################################
# Remove spool files before executing reports
#############################################
rm -f _feedr.sum fl_recharge.lst  fl_cnt.lst 1>/dev/null 2>>/dev/null

###############################################################################
# Obtain number of records written to  invoice table & spool it to fl_cnt.lst
###############################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/fsmfleet_feeder_mth04.sql  $ORGID $SITEID
    exit sql.sqlcode
SQL_END2


# If the file does not exist
if [[ ! -a fl_cnt.lst ]]
then
   exit 0;
fi

#############################################################
# Exit if there are no records in 'invoice' table
# and report to administrator
#############################################################
REC_CNT=`cat fl_cnt.lst`
FL_CNT=`echo $REC_CNT || awk '{print substr($REC_CNT,1,1) }' `
if [[ "$FL_CNT" = "0" ]]
then
   /usr/ucb/Mail -s "Monthly Fleet Recharge Program" $MAIL_REC < $MXES_SITE_HOME/dat/fl_empty1.dat
   cp $MXES_SITE_HOME/dat/fl_empty1.dat $MXES_SITE_HOME/log/fl_recharge.$FILESUF
   exit 0;
fi

echo 'Fleet feeder file preparation started @' `date` >> fl_joblog

##################################################################
# Now dump the contents of the table into csv file
# recognized by FMS Feeder
##################################################################

rm -f $MAXIMOFEEDERDIR/mot.csv $MAXIMOFEEDERDIR/mot.cnt 1>/dev/null 2>>/dev/null

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END6
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/format_projfdr.sql $ORGID $SITEID MOT
    exit sql.sqlcode
SQL_END6

SQL_EXIT2=$?

#
 case "$SQL_EXIT2"
 in
   0)  print 'Fleet Feeder file prepration Completed @'   `date` '- job ended successfully' >> fl_joblog;;
   *)  print 'Fleet Feeder file preparation Terminated@'   `date` '- error exit:' $SQL_EXIT2  >> fl_joblog;;
   esac
#

############################################################################
# Copy feeder file to xfer directory so that FMS feeder can pickup that file
############################################################################


if [[ "$EXEC_ENV" = "P" ]] then
 cp $MAXIMOFEEDERDIR/mot.csv /xfer/fms/prod/feeder/mot_csv/.
 cp $MXES_SITE_HOME/dat/express   /xfer/fms/prod/feeder/mot_csv/express_csv
fi

cp $MAXIMOFEEDERDIR/mot.csv $MXES_SITE_HOME/dat/mot.csv.$FILESUF
cp $MAXIMOFEEDERDIR/mot.cnt $MXES_SITE_HOME/dat/mot.cnt.$FILESUF

echo 'Generation of fleet recharge report started @' `date` >> fl_joblog

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
    start $MXES_SITE_HOME/sql/fsmfleet_feeder_mth02.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END3

SQL_EXIT=$?

#
 case "$SQL_EXIT"
 in
   0)  print 'Generation of fleet recharge report Completed @'   `date` '- job ended successfully' >> fl_joblog;;
   *)  print 'Generation of fleet recharge Report Terminated@'   `date` '- error exit:' $SQL_EXIT  >> fl_joblog;;
   esac
#


# If the file does not exist
if [[ ! -a fl_recharge.lst ]]
then
   exit 0;
fi

/usr/ucb/Mail -s "Monthly Fleet Recharge Report" $MAIL_REC < fl_recharge.lst

if [[ "$EXEC_ENV" = "P" ]] then
 /usr/ucb/Mail -s "Monthly Fleet Recharge Report" KJPorter@lbl.gov  < fl_recharge.lst
 /usr/ucb/Mail -s "Monthly Fleet Recharge Report" TLThompson@lbl.gov  < fl_recharge.lst
fi

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
    /usr/ucb/Mail -s "FLEET Recharge Control Totals" $EMAIL_ID < $MAXIMOFEEDERDIR/mot.cnt
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
    start $MXES_SITE_HOME/sql/updtperd.sql 'MOT' $ORGID
    exit sql.sqlcode
SQL_END8

SQL_EXIT4=$?

#
 case "$SQL_EXIT4"
 in
   0)  print 'Updated financialperiods successfully @'   `date` '- job ended successfully' >> fl_joblog;;
   *)  print 'Update to financialperiods FAILED @'   `date` '- error exit:' $SQL_EXIT  >> fl_joblog;;
   esac
#

# Remove the temporary files
rm -f  fl_joblog fl_feedr.sum fl_cnt.lst fl_recharge.lst  1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2+$SQL_EXIT4))

exit $SQL_EXIT
