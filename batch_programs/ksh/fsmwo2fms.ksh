#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Send work order information to FMS project interface tables
#
#
# Module Name  : fsmwo2fms.sql
# Schedule     : Every day
#============================================================================
# Maintenance Log:
#============================================================================


# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$FSMWONUM2FMS_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog.lst 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog.lst
print 'Sending work orders to FMS projects  started @' `date`  >> joblog.lst
print '==========================================================================' >> joblog.lst


# Now start actual extraction

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool joblog
    start $MXES_SITE_HOME/sql/sendwo2fms.sql $ORGID $SITEID PASS1
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

mv joblog.lst $MXES_SITE_HOME/log/fsmwo2fms.$FILESUF
#/usr/ucb/Mail -s "Sending work orders to FMS-Pass completed" $MAIL_REC < $MXES_SITE_HOME/log/fsmwo2fms.$FILESUF

exit $SQL_EXIT
