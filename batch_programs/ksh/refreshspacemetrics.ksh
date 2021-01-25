#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Archibus
#                Refresh space metrics information
#
# Module Name  : refreshspacemetrics.ksh
# Schedule     :
#============================================================================
# Maintenance Log:
#============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/archibus.env


if [[ "$REFRSHSPACEMETRICS_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog  1>/dev/null 2>>/dev/null

print '===============================================================================' > joblog
print 'Refresh space metrics information started @' `date`  >> joblog
print '===============================================================================' >> joblog

# Now start execution

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${ARCH_META_CONTENT}
    set document off
    set termout off
    set define off
    set serveroutput on
    spool joblog
    start $MXES_SITE_HOME/sql/refreshspacemetrics.sql
    spool off
    exit sql.sqlcode
SQL_END2

SQL_EXIT=$?

cat joblog.lst >> joblog

#
 case "$SQL_EXIT"
 in
   0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog;;
   esac
#


mv joblog $MXES_SITE_HOME/log/refreshspacemetrics.log.$FILESUF

exit $SQL_EXIT