#!/bin/ksh
#=====================================================================
# Installation : Berkeley Lab
# Application: 	Maximo
#
#		Execute java program to import the recipient
#               information required for IBOX from MAXIMO
#
#
#
# Module Name:  impiboxrecipient.ksh
#
# Schedule:
#=====================================================================

# Set environment

export MXES_HOME=$HOME/`cat $HOME/mxes7_dir`
. $MXES_HOME/dat/max_fac.env


## Check whether to run the program or not
if [[ "$IMPIBOXRECIPIENT_ENABLE" == "0" ]]
 then
   exit 0;
fi

rm -f $MXES_HOME/fac/java/bin/lbl/impiboxrecipient.log  1>/dev/null 2>>/dev/null

export FILESUF   FILESUF=`date '+%y%m%d%H%M'`

CLASSPATH=$MXES_HOME/fac/java/bin:$MXES_HOME/fac/java/lib/ojdbc14.jar:$MXES_HOME/fac/java/lib/mail.jar:$MXES_HOME/fac/java/lib/activation.jar

export CLASSPATH

cd $MXES_HOME/fac/java/bin

java lbl.ImpIboxRecipient $ORGID $SITEID >impiboxrecipient.log 2>&1

#use the below line if we need to refresh the domains
#java lbl.ImpIboxRecipient $ORGID $SITEID load_locationspec_data >impiboxrecipient.log 2>&1

PROGRAM_EXIT=$?

#
 case "$PROGRAM_EXIT"
 in
   0)  print 'Import IBOX Recipient Job Completed @'   `date` '- job ended successfully' >> impiboxrecipient.log;;
   *)  print 'Import IBOX Recipient Job Failed @'    `date` '- job failed' >> impiboxrecipient.log;;
   esac

mv $MXES_HOME/fac/java/bin/impiboxrecipient.log  $MXES_HOME/fac/log/impiboxrecipient.log.$FILESUF

exit $PROGRAM_EXIT
