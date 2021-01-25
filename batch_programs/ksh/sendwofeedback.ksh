#!/bin/ksh
#=====================================================================
# Installation : Berkeley Lab
# Application: 	Maximo
#
#		Execute java program process the following:
#
#               Work Order Feedback Reporting
#
# Module Name:  sendwofeedback.ksh
#
# Schedule:
#=====================================================================

# Set environment
export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


## Check whether to run the program or not
if [[ "$SENDWOFEEDBACK_ENABLE" == "0" ]]
 then
   exit 0;
fi

rm -f $MXES_HOME/fac/java/bin/sendwofeedback.log  1>/dev/null 2>>/dev/null

export FILESUF   FILESUF=`date '+%y%m%d%H%M'`


CLASSPATH=$MXES_HOME/fac/java/bin:$MXES_HOME/fac/java/lib/mail.jar:$MXES_HOME/fac/java/lib/activation.jar:$MXES_HOME/fac/java/lib/poi-3.0-rc4-20070503.jar:$MXES_HOME/fac/java/lib/classes12.zip

export CLASSPATH

cd $MXES_HOME/fac/java/bin

$MXES_JAVA -Djava.awt.headless=true lbl.SendWOFeedback $ORGID $SITEID    >sendwofeedback.log 2>&1

PROGRAM_EXIT=$?

#
 case "$PROGRAM_EXIT"
 in
   0)  print 'Work order Feeback Reports Job Completed @'   `date` '- job ended successfully' >> sendwofeedback.log;;
   *)  print 'Work order Feeback Reports Job Failed @'    `date` '- job failed' >> sendwofeedback.log;;
   esac

mv $MXES_HOME/fac/java/bin/sendwofeedback.log  $MXES_HOME/fac/log/sendwofeedback.log.$FILESUF 
mv $MXES_HOME/fac/java/bin/*.xls $MXES_HOME/fac/log/sendwofeedback.xls.$FILESUF

#/usr/ucb/Mail -s "Work order Feeback Reports Job" $MAIL_REC < $MXES_HOME/fac/log/sendwofeedback.log.$FILESUF

exit $PROGRAM_EXIT
