#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Script to be executed for post db cloning procedure
#
# Module Name  : postdbcloning.ksh
#
#============================================================================
# Maintenance Log:
#============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env



export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog joblog.lst 1>/dev/null 2>>/dev/null




echo "Database on which cloning procedure to be applied: " $1
if [ ${#} -ne 1 ]
then
    echo "ERROR: Must provide the name of cloned database"
    exit 1

fi

CLONED_DB=$1
MAX_META_CONTENT_NEW=${MAX_META_CONTENT%@*}@$CLONED_DB



print '===================================================' > joblog
print 'POST cloning for $CLONED_DB started @' `date`  >> joblog
print '=========================================-==========' >> joblog

# Now start actual cloning
${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT_NEW}
    set document off
    set termout off
    set serveroutput on
    spool postdbcloning
    start $MXES_SITE_HOME/sql/postdbcloning.sql $CLONED_DB
    spool off
    exit sql.sqlcode
SQL_END2


SQL_EXIT=0

#
 case "$SQL_EXIT"
 in
   0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog;;
   esac
#


mv joblog $MXES_SITE_HOME/log/pstclonedb.log.$FILESUF

exit $SQL_EXIT
