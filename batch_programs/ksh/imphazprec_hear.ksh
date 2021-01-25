#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Driver script for importing hazards/precuation information
#                HMS to MAXIMO.
#
# Module Name  : imphazprec_hear.ksh
# Schedule     : Every day
#============================================================================
# Maintenance Log:
#============================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


if [[ "$IMPHAZPREC_HEAR_ENABLE" == "0" ]]
 then
   exit 0;
fi

export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Import Hazard/Precaution information started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Now start actual extraction

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
    set document off
    set termout off
    set serveroutput on
    spool joblog
    start $MXES_SITE_HOME/sql/imphazprec_hear.sql $ORGID $SITEID
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

mv joblog $MXES_SITE_HOME/log/imphazprec_hear.$FILESUF
#/usr/ucb/Mail -s "Import Hazard/Precaution information completed" $MAIL_REC < $MXES_SITE_HOME/log/imphazprec_hear.$FILESUF

exit $SQL_EXIT
