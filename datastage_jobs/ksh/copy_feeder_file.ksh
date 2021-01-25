#! /bin/ksh
######################################################################################
# Project   : LBNL
# Author    : Pankaj Bhide
# Ver 1.0   : Initial Version
# Modified Date: Feb 22 2019
# Modified By:
# Notes     : This script copies the feeder project file to the requisite folders
#             based upon the environment
# Execution : ./copy_feeder_file.ksh <feeder_name> <environment>
#===================================================================================

#
#===================================================================================
# Check Script Usage
#===================================================================================

if [[ $# -ne 2 ]]
then
        echo "USAGE: ./copy_feeder_file.ksh <feeder_name> <environment>"
        exit 1
fi

#===================================================================================
# Prepare variables
#===================================================================================
FEEDER_NAME=$1
ENVIRONMENT=$2

#feeder_data_directory='/home/dsadm/itbs_shared/fac/dat'
#feeder_data_directory='/home/dsadm/etl-app01/dsadm/itbs_shared/fac/dat'
feeder_data_directory='/home/dsadm/etl-app01/itbs_shared/fac/dat'

source_express_file=$feeder_data_directory'/express_csv'
echo $feeder_data_directory
echo $source_express_file

return1=0
return2=0
return3=0

export FILESUF   FILESUF=`date '+%y%m%d'`

if [[ $ENVIRONMENT = "PRODUCTION" ]] then
   feeder_output_directory='/xfer/fms/prod/feeder'
   #feeder_output_directory='/home/dsadm/itbs_shared/fac/dat/t1'
else
  #feeder_output_directory='/home/dsadm/itbs_shared/fac/dat/t1'
   feeder_output_directory='/home/dsadm/etl-app01/itbs_shared/fac/dat/t1'
fi

echo $feeder_output_directory

if [[ $FEEDER_NAME = "STG" ]] then
        source_file=$feeder_data_directory/'stg.csv'
        target_file=$feeder_output_directory'/stg_csv/stg.csv'
        target_copied_file=$feeder_data_directory'/stg_csv.'$FILESUF
        target_express_file=$feeder_output_directory'/stg_csv/express_csv'
fi

if [[ $FEEDER_NAME = "STR" ]] then
        source_file=$feeder_data_directory/'str.csv'
        target_file=$feeder_output_directory'/str_csv/str.csv'
        target_copied_file=$feeder_data_directory'/str_csv.'$FILESUF
        target_express_file=$feeder_output_directory'/str_csv/express_csv'
fi

if [[ $FEEDER_NAME = "MOT" ]] then
        source_file=$feeder_data_directory/'mot.csv'
        target_file=$feeder_output_directory'/mot_csv/mot.csv'
        target_copied_file=$feeder_data_directory'/mot_csv.'$FILESUF
        target_express_file=$feeder_output_directory'/mot_csv/express_csv'
fi


# Check whether the input file exists
if [[ -e "$source_file" ]] then  
 :
else
  echo $source_file
  echo 'Error: source file not found'
  exit 1 
fi

# Start copying the files
cp $source_file $target_file
return1=$?
cp $source_express_file $target_express_file
return2=$?
mv $source_file $target_copied_file
return3=$?

# Return the combined returned status to the shell

return0=$(($return1 +$return2 +$return3))
exit $return0

