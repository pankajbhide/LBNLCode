#! /bin/ksh
#outhor    : Pankaj Bhide
#
# Ver 1.0   : Initial Version
# Modified Date: March 24 2020
# Modified By:
# Notes     : This script encyrpts the input file
# Execution : ./lbl_encrypt.ksh <input_file> <paraphrase_file>
#===================================================================================


#===================================================================================
# Check Script Usage
#===================================================================================

if [[ $# -ne 2 ]]
then
        echo syntax ./lbl_encrypt.ksh input_file paraphrase_file
        exit 1
fi


export FILESUF   FILESUF=`date '+%y%m%d'`


#===================================================================================
# Prepare variables
#===================================================================================
INPUT_FILE=$1
PARAPHRASE_FILE=$2
OUTPUT_FILE=$2'.gpg'
OUTPUT_FILE_ARCH=$2'.gpg.'$FILESUF
TARGET_FILE='/home/dsadm/itbs_shared/ehs/emr/output/'$OUTPUT_FILE
TARGET_FILE_ARCH='/home/dsadm/itbs_shared/ehs/emr/output/'$OUTPUT_FILE_ARCH

 echo $OUTPUT_FILE
echo $TARGET_FILE
echo $TARGET_FILE_ARCH

# Check whether the input file exists
if [[ -e "$INPUT_FILE" ]] then 
 :
else
  echo 'Error: input file not found'
  exit 1
fi

# Check whether the paraphrase file exists
if [[ -e "$PARAPHRASE_FILE" ]] then 
 :
else
  echo 'Error: paraphrase file not found'
  exit 1
fi



return1=0
return2=0
return3=0

# Execute main command
gpg --batch -c --passphrase-file $PARAPHRASE_FILE $INPUT_FILE
return1=$?


# Check whether the  file exists
if [[ -e "$OUTPUT_FILE" ]] then 
 :
else
  echo 'Error in generating encrypted file.'
  exit 1
fi


# Start copying the files
cp $OUTPUT_FILE $TARGET_FILE
return2=$?

cp $OUTPUT_FILE $TARGET_FILE_ARCH
return3=$?


# Return the combined returned status to the shell

return0=$(($return1 +$return2 +$return3))
exit $return0

