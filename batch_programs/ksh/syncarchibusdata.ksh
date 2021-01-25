#! /bin/ksh
#============================================================================
# Installation : Berkeley Lab
# Application  : Maximo
#                Driver script for executing the programs for synchroniozing
#                data in Archibus
#
# Module Name  : syncarchibusdata.ksh
# Schedule     : Every day
#
#
#============================================================================
# Maintenance Log:
#============================================================================

# Set environment



export MXES_HOME=$HOME/`cat $HOME/mxes_dir`
. $MXES_HOME/dat/max_fac.env



if [[ "$SYNCARCHIBUSDATA_ENABLE" == "0" ]]
 then
  exit 0;
fi


export FILESUF   FILESUF=`date '+%y%m%d'`

PATH=$PATH:$MXES_SITE_HOME/ksh:/usr/bin:/usr/ucb:/opt/bin:/usr/local/bin

rm -f joblog joblog3 joblog2.lst 1>/dev/null 2>>/dev/null

print '==========================================================================' > joblog
print 'Synchronize Archibus data  started @' `date`  >> joblog
print '==========================================================================' >> joblog

# Now start actual SQL program for organization structure

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END2
${MAX_META_CONTENT}
   set document off
   set termout off
   set verify off
   set serveroutput on
   spool joblog
   start $MXES_SITE_HOME/sql/sync_org_structure21.sql
   spool off
   exit sql.sqlcode
SQL_END2

SQL_EXIT1=$?


# SQL program for employees

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END3
${MAX_META_CONTENT}
   set document off
   set termout off
   set verify off
   set serveroutput on
   spool joblog2
   start $MXES_SITE_HOME/sql/sync_employee21.sql
   spool off
   exit sql.sqlcode
SQL_END3

SQL_EXIT2=$?


# SQL program for level2-level4 for rooms

${ORACLE_HOME}/bin/sqlplus -s  << SQL_END4
${MAX_META_CONTENT}
   set document off
   set termout off
   set verify off
   set serveroutput on
   spool joblog2
   start $MXES_SITE_HOME/sql/sync_room_org_structure21.sql
   spool off
   exit sql.sqlcode
SQL_END4

SQL_EXIT3=$?


# Add up the exit status, if not equal to zero means error

SQL_EXIT=$(($SQL_EXIT1+$SQL_EXIT2+$SQL_EXIT3))

#
 case "$SQL_EXIT"
 in
  0)  print 'Job Completed @'   `date` '- job ended successfully' >> joblog;;
  *)  print 'Job Terminated@'   `date` '- error exit:' $SQL_EXIT  >> joblog;;
  esac
#
cat joblog joblog.lst joblog2.lst >> joblog3

mv joblog3 $MXES_SITE_HOME/log/syncarchibusdata.log.$FILESUF
#/usr/ucb/Mail -s "Synchronization of Archibus data completed" $MAIL_REC < $MXES_SITE_HOME/log/syncarchibusdata.log.$FILESUF

exit $SQL_EXIT