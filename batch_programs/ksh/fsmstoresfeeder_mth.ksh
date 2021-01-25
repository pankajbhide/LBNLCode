#! /bin/ksh
#==============================================================================
# Installation : Berkeley Lab
#
# Application  : Stores
#
#                Execute PL/SQL scripts for Monthly Stores (STG)
#                URF feeder and copy the file to the specific directory
#
# Author       : Pankaj Bhide
#
# Module Name  : fsmstoresfeeder_mth.ksh
#
# Schedule     : At the end of every account period (Accelerated close)
#
# Date written : 06-MAY-2014
#
#
# Modification
# History      : JULY 25-2016 = Pankaj - Changes for STG (project feeder)
#=============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$FSMSTORESFEEDER_MTH_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:.

rm -f storesfeeder.log  proj.dat 1>/dev/null 2>>/dev/null


echo '========================================='    > storesfeeder.joblog
echo 'Job Log of fsmstoresfeeder.ksh '                >> storesfeeder.joblog
echo '========================================='   >> storesfeeder.joblog
echo 'FSM Stores Feeder Processing started @' `date`   >> storesfeeder.joblog


####################################################
# Start populating records in lbl_itemsummary table
####################################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END0
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/build_itemsummary $ORGID $SITEID LAST
    exit sql.sqlcode
SQL_END0

SQL_EXIT0=$?

#
 case "$SQL_EXIT0"
 in
   0)  print 'Populated the records in lbl_itemsummary table. @'   `date` '- job ended successfully' >> storesfeeder.joblog;;
   *)  print 'Failed to populate records in lbl_itemsummary table. Terminated @'   `date` '- error exit:' $SQL_EXIT0  >> storesfeeder.joblog; exit 1;;
   esac



#######################################
# Start preparing the feeder records
#######################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/gen_stgprojfeeder.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'Preparation of Stores Feeder records(details) Completed @'   `date` '- job ended successfully' >> storesfeeder.joblog;;
   *)  print 'Preparation of Stores Feeder records(details) Terminated @'  `date` '- error exit:' $SQL_EXIT1  >> storesfeeder.joblog; exit 1;;
   esac
#



######################################################
# Start preparing proj feeder file (CSV)
######################################################
${ORACLE_HOME}/bin/sqlplus -s << SQL_END19
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/format_projfdr.sql $ORGID $SITEID STG
    exit sql.sqlcode
SQL_END19

SQL_EXIT3=$?

#
 case "$SQL_EXIT3"
 in
   0)  print 'Preparation of STG Proj Feeder file Completed @'   `date` '- job ended successfully' >> storesfeeder.joblog;;
   *)  print 'Preparation of STG Proj Feeder file Terminated @'   `date` '- error exit:' $SQL_EXIT3  >> storesfeeder.joblog; exit 1;;
   esac
#


############################################################################
# Copy feeder file to xfer directory so that FMS feeder can pickup that file
############################################################################

if [[ "$EXEC_ENV" = "P" ]] then
 cp $MAXIMOFEEDERDIR/stg.csv /xfer/fms/prod/feeder/stg_csv/.
 cp $MXES_SITE_HOME/dat/express   /xfer/fms/prod/feeder/stg_csv/express_csv
fi

cp $MAXIMOFEEDERDIR/stg.csv $MXES_SITE_HOME/dat/stg.csv.$FILESUF
cp $MAXIMOFEEDERDIR/stg.cnt $MXES_SITE_HOME/dat/stg.cnt.$FILESUF



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

    if [[ "$EXEC_ENV" = "P" ]] then

      /usr/ucb/Mail -s "Stores (STG) Proj Control Totals" $EMAIL_ID < $MAXIMOFEEDERDIR/stg.cnt
    else

      /usr/ucb/Mail -s "Stores (STG) Proj Control Totals" $MAIL_REC < $MAXIMOFEEDERDIR/stg.cnt
    fi

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
    start $MXES_SITE_HOME/sql/updtperd.sql STG $ORGID
    exit sql.sqlcode
SQL_END8

SQL_EXIT4=$?

#
 case "$SQL_EXIT4"
 in
   0)  print 'Updated financialperiods successfully @'   `date` '- job ended successfully' >> storesfeeder.joblog;;
   *)  print 'Update to financialperiods FAILED @'   `date` '- error exit:' $SQL_EXIT4  >> storesfeeder.joblog; exit 1;;
   esac
#

/usr/ucb/Mail -s "JOBLOG of Stores Feeder (month-end)" $MAIL_REC < storesfeeder.joblog

mv storesfeeder.joblog       $MXES_SITE_HOME/log/storesfeeder.joblog.$FILESUF

rm -f proj.dat 1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT0+$SQL_EXIT1+$SQL_EXIT3+$SQL_EXIT4))

exit $SQL_EXIT
