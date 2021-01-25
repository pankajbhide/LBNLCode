#!/bin/ksh
#=====================================================================
# Installation : Berkeley Lab
# Application: 	Maximo
#
#		Execute java program process the following:
#
#               WO Acknowledgment
#               Notification after completion
#               Alert to the supervisor for feedback
#
# Module Name:  woacknotifalert.ksh
#
# Schedule:
#=====================================================================

# Set environment


export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


## Check whether to run the program or not
if [[ "$WO_ACK_NOTIFY_ALERT_ENABLE" == "0" ]]
 then
   exit 0;
fi

rm -f $MXES_HOME/fac/java/bin/lbl/lbl_wo_ack_notify.log  1>/dev/null 2>>/dev/null

#
if   [ -n "$MXES_HOME/fac/log/lbl_wo_ack_notify.*" ]
then find $MXES_HOME/fac/log/lbl_wo_ack_notify.* -ctime +120 -exec /bin/rm -f {} \;
fi
#

export FILESUF   FILESUF=`date '+%y%m%d%H%M'`

CLASSPATH=$MXES_HOME/fac/java/bin:$MXES_HOME/fac/java/lib/ojdbc14.jar:$MXES_HOME/fac/java/lib/mail.jar:$MXES_HOME/fac/java/lib/activation.jar

export CLASSPATH

cd $MXES_HOME/fac/java/bin

java lbl.WOAckNotifAlert $ORGID $SITEID >lbl_wo_ack_notify.log 2>&1

PROGRAM_EXIT=$?

#
 case "$PROGRAM_EXIT"
 in
   0)  print 'Work order Acknowlegment/Notification Job Completed @'   `date` '- job ended successfully' >> lbl_wo_ack_notify.log;;
   *)  print 'Work order Acknowlegment/Notification Job Failed @'    `date` '- job failed' >> lbl_wo_ack_notify.log;;
   esac

mv $MXES_HOME/fac/java/bin/lbl_wo_ack_notify.log  $MXES_HOME/fac/log/lbl_wo_ack_notify.log.$FILESUF

exit $PROGRAM_EXIT
