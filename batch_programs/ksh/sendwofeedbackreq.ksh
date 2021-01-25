#! /bin/ksh
#===============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Execute script to select work orders for feedback and send
#                email notification for submitting the feedback.
#
# Module Name  : sendwofeedbackreq.ksh
# Schedule     : Weekly, as required
#
#===============================================================================
# Maintenance Log:
#===============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Selecting work orders for feedback started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Select work orders for feedback

${ORACLE_HOME}/bin/sqlplus -s << SQL_END1
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool log
    start $MXES_SITE_HOME/sql/selectwo4feedback.sql
    spool off
    exit sql.sqlcode
SQL_END1

SQL_EXIT1=$?

#
 case "$SQL_EXIT1"
 in
   0)  print 'Selecting work orders for feedback Job Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Selecting work orders for feedback Job  Terminated@'   `date` '- error exit:' $SQL_EXIT1  >> joblog; cat log.lst >> joblog;;
   esac
# Send email requesting them to submit feedback

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END6
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool log
    start $MXES_SITE_HOME/sql/send_feedback_em.sql
    spool off
    exit sql.sqlcode
SQL_END6

SQL_EXIT2=$?

#
 case "$SQL_EXIT2"
 in
   0)  print 'Sending wofeedback Completed @'   `date` '- job ended successfully' >> joblog;;
   *)  print 'Sending wofeedback Terminated@'   `date` '- error exit:' $SQL_EXIT2  >> joblog; cat log.lst >> joblog;;
   esac

print '  ' >> joblog


mv  joblog $MXES_SITE_HOME/log/sendwofeedbackreq.joblog.$FILESUF

#rm -f log.lst 1>/dev/null 2>>/dev/null

# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2))

exit $SQL_EXIT