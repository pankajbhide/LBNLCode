#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Driver script for importing building, floor, room information
#                from Archibus to MAXIMO
#                MAXIMO.
#
# Module Name  : importarchibus2max.ksh
# Schedule     : Every day
#
#
# Maintenance Log:
#============================================================================


# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$IMPARCHIBUS2MAX_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog joblog2.lst 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Import of Archibus data started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Now start actual extraction


${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool joblog2
    start $MXES_SITE_HOME/sql/imparchibus2max.sql
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
cat joblog2.lst >> joblog

mv joblog $MXES_SITE_HOME/log/imparchibus2max.log.$FILESUF
#/usr/ucb/Mail -s "Import Archibus information completed" $MAIL_REC < $MXES_SITE_HOME/log/impachibus2max.log.$FILESUF

exit $SQL_EXIT
