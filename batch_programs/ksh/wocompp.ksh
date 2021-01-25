#! /bin/ksh
#===============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Execute PL/SQL scripts to change the status of the work orders
#                from COMP-WCLOSE and WCLOSE-CLOSE.
#
# Module Name  : WOCOMPP.ksh
# Schedule     : Daily, as required
#
#===============================================================================
# Maintenance Log:
#===============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env

if [[ "$WOCOMPP_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Changing the status of work orders from COMP to WCLOSE   started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Now start processing to mark workorders for WCLOSE

${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool log
    start $MXES_SITE_HOME/sql/wocompp1.sql $ORGID $SITEID
    spool off
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'COMP-WCLOSE Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'COMP-WCLOSE Job Terminated@'   `date` '- error exit:' $SQL_EXIT1  >> joblog; cat log.lst >> joblog;;
   esac
#

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END6
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool log
    start $MXES_SITE_HOME/sql/wocompp2.sql $ORGID $SITEID
    spool off
    exit sql.sqlcode
SQL_END6

SQL_EXIT2=$?

#
 case "$SQL_EXIT2"
 in
   0)  print 'WCLOSE-CLOSE Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'WCLOSE-CLOSE Job Terminated@'   `date` '- error exit:' $SQL_EXIT2  >> joblog; cat log.lst >> joblog;;
   esac

print '  ' >> joblog


mv  joblog $MXES_SITE_HOME/log/wocompp.$FILESUF

#rm -f log.lst 1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2))

exit $SQL_EXIT
