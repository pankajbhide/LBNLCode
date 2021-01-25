#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Send email to divisional safety coordinators upon inactivation
#                of authorizers
#
#
# Module Name  : sendemailinactauth.ksh
# Schedule     : Once a week
#============================================================================
# Maintenance Log:
#============================================================================


# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$SENDEMAILINACTAUTH_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog.lst 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog.lst
print 'Program  started @' `date`  >> joblog.lst
print '==========================================================================' >> joblog.lst


# Now start actual program

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set define off
    set serveroutput on
    spool joblog
    start $MXES_SITE_HOME/sql/sendemailinactauth.sql
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

mv joblog.lst $MXES_SITE_HOME/log/sendemailinactauth.log.$FILESUF

exit $SQL_EXIT
