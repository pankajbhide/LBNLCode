#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Driver script for calculating the delta between inventory 
#                balances
#
# Module Name  : calc_invbalances_delta.ksh
# Schedule     : Every day
#============================================================================
# Maintenance Log:
#============================================================================


# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$CALC_INVBALANCES_DELTA_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog.lst 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog.lst
print 'Program for calculating inventory balances delta started @' `date`          >> joblog.lst
print '==========================================================================' >> joblog.lst

# Now start actual extraction

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    set serveroutput off
    spool joblog
    start $MXES_SITE_HOME/sql/calc_invbalances_delta.sql $ORGID $SITEID
    spool off
    exit sql.sqlcode
SQL_END2

SQL_EXIT=$?

#
 case "$SQL_EXIT"
 in
   0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog.lst;;
   *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog.lst;;
   esac
#

rm -f inv_deltabalances_rec_cnt.lst 1>/dev/null 2>>/dev/null

######################################################################
# Obtain number of records from table
######################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/inv_deltabalances_rec_cnt.sql $ORGID $SITEID
    exit sql.sqlcode
SQL_END2


# If the file does not exist
if [[ ! -a inv_deltabalances_rec_cnt.lst ]]
then
   exit 0;
fi

######################################################################
# Generate the report to get the delta details
######################################################################
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set echo off
    set feedback off
    set verify off
    start $MXES_SITE_HOME/sql/inv_deltabalances_report.sql  $ORGID $SITEID
    exit sql.sqlcode
SQL_END2

#####################################################################
# Exit if there are no records in delta table report to administrator
#####################################################################
REC_CNT=`cat inv_deltabalances_rec_cnt.lst`
FL_CNT=`echo $REC_CNT || awk '{print substr($REC_CNT,1,1) }' `
if [[ "$FL_CNT" = "0" ]]
then
   exit 0;
fi

if test -r $MXES_SITE_HOME/dat/inv_deltabalances_mail.dat
then

# Now scan all records in this file and send notification to every person
# listed in that file

for line in `cat $MXES_SITE_HOME/dat/inv_deltabalances_mail.dat`
do
    EMAIL_ID=`echo $line`
    /usr/ucb/Mail -s "Inconsistencies found in inventory balances and calculated balances" $EMAIL_ID < inv_deltabalances_report.lst
done
fi

echo 'Procss to extract delta completed @' `date` >> joblog.lst
mv joblog.lst $MXES_SITE_HOME/log/calc_invbalances_delta.log.$FILESUF

exit 0;


