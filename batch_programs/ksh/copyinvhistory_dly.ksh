#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Driver script for copying the data from invetory releated
#                tables.
#
# Module Name  : copyinvhistory_dlyksh
# Schedule     : Every day
#============================================================================
# Maintenance Log:
#============================================================================


# Set environment


export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$COPYINVHISTORY_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Copying inventory related information(daily) started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Now start actual extraction

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool joblog
    start $MXES_SITE_HOME/sql/copyinvhistory_dly.sql $ORGID $SITEID
    spool off
    exit sql.sqlcode
SQL_END2

SQL_EXIT=$?

#
 case "$SQL_EXIT"
 in
   0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog;;
   esac
#

cat joblog.lst >> joblog
rm -f joblog.lst

mv joblog $MXES_SITE_HOME/log/copyinvhistory2.$FILESUF
#/usr/ucb/Mail -s "Copying inventory related information (daily) completed" $MAIL_REC < $MXES_SITE_HOME/log/copyinvhistory2.$FILESUF

exit $SQL_EXIT
