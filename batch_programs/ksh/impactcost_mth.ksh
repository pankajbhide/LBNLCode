#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Import actuals dollars from DW to MAXIMO
#
# Module Name  : impactcost_mth.ksh
# Schedule     : Every 5th day of the month
#============================================================================
# Maintenance Log: 
#============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$IMPACTCOST_MTH_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog actuals.lst 1>/dev/null 2>>/dev/null

print '===============================================================================' > joblog
print 'Monthly process to bring actual dollars started @' `date`  >> joblog
print '===============================================================================' >> joblog

# Now start actual extraction

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool actuals
    start $MXES_SITE_HOME/sql/impactcost_mth.sql $ORGID $SITEID LAST
    spool off
    exit sql.sqlcode
SQL_END2

SQL_EXIT=$?

cat actuals.lst >> joblog

#
 case "$SQL_EXIT"
 in
   0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog;;
   esac
#

rm -f actuals.lst
mv joblog $MXES_SITE_HOME/log/impactcost_mth.log.$FILESUF
/usr/ucb/Mail -s "Monthly process to bring dollars completed." $MAIL_REC < $MXES_SITE_HOME/log/impactcost_mth.log.$FILESUF

exit $SQL_EXIT
