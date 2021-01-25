#! /bin/ksh
######################################################################################
# Project   : LBNL
# Author    : Pankaj Bhide
# Ver 1.0   : Initial Version
# Modified Date: July 10, 2019
# Modified By:
# Notes     : This script performs SFTP from chemicalsafety.com and
#             copies to the target directory with backup copy with
#             datestamp
# Execution : ./wmsftp.ksh
#===================================================================================



#===================================================================================
# Prepare variables
#===================================================================================


source_data_file='/download/B85_isotope_inventory_1.txt'
copied_file='/home/dsadm/itbs_shared/ehs/wm/B85_isotope_inventory_1.txt'

host='LBNLab@ftp.chemicalsafety.com'
port='22000'

# Remove the file if already exists
rm -f $copied_file joblog.log 2>&1 > /dev/null


export FILESUF   FILESUF=`date '+%y%m%d'`

##################
# Perform SFTP
##################
sftp -P $port $host <<END_SCRIPT
get $source_data_file $copied_file
quit
END_SCRIPT

#########################################
# Check whether the copied file exists
#########################################
if [[ -e "$copied_file" ]] then  
 print "found file"
else
  print "Error: Possible error during SFTP@  " `date` "- job ended un-successfully."> joblog.log 
  exit 1 
fi


##############################################
# Check whether the copied file has some data
##############################################

if [[ -s "$copied_file" ]] then
  print "found some data"
else
  print "Error: Copied file is empty@ "   `date` "- job ended un-successfully." >> joblog.log
  exit 1   
fi
############################################################
# Find out number of lines in the file. The number of lines
# should be greater than 1
############################################################

no_of_lines=$((`wc -l <$copied_file`))
needed_lines=1

if [[ "$no_of_lines" -gt "$needed_lines" ]]  then
    print "good data"
else
    print "Error: Copied file contains only 1 row "   `date` "- job ended un-successfully." >> joblog.log
    exit 1   
fi


arch_copied_file=$copied_file'.'$FILESUF
cp $copied_file $arch_copied_file 
exit_code=$?

exit $exit_code
