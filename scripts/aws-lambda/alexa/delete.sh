#!/bin/bash
###########################################################################
#
# Script        : delete.sh
# Purpose       : Delete a lambda function, and execute a named purge script for cleanup.
# Authors       : Steve Robinson - http://www.blueboxblue.com steve@blueboxblue.com
# Created       : April 2018 for DevOps course
# 
# History
# date           ver  who  what 
# ----           ---  ---  ----
# 19-April-2018  0.1  scr  Updated the first version to new format
# 04-May-2018    0.2  scr  Added correct query syntax to return matched function name or empty if not found.
#

##########################################################################
#
# showHelp() - display full help
#
##########################################################################
showHelp() {

    echo "Usage: ${0##*/} -n <Enter function name e.g myfunc1>"
    echo 
    echo "Delete Lamda Function"
    echo "Options:"
    echo "  -n           Delete Lambda function by name"
	echo "  -p           Name of local purge script ie callable script"
	echo "  -h           This help message"
    exit 1
    
}
 
##########################################################################
#
# validateArgs() - parameter validation
#
##########################################################################
validateArgs() 
{ 
    
    while getopts ":hn:p:"  opt; do
        echo "\$opt=$opt$, \$OPTIND=$OPTIND, \$OPTARG=$OPTARG"
        case $opt in
       
        n)  export FUNCTION_NAME="${OPTARG}"
	        ;;
			
		p)  export PURGE_FILE="${OPTARG}"
	        ;;
			
		h)  showHelp
            ;;
			
		\?) echo "No option specified"
			;;
 
        *)  echo "Invalid option -${OPTARG}">&2
            showHelp
			exit 0
            ;;
 
		esac
    done
 
    shift $((OPTIND - 1))
 
    if [ $# -ne 0 ]
    then
        showHelp
		exit 1
    fi
 
}

#################################################################
# MAIN ENTRY POINT
################################################################
TODAY=$(date +"%d%B%Y")
DATE_FORMAT="+%d/%B/%Y %T"
THIS_SCRIPT=${0##*/}
THIS_SCRIPT=$(basename $THIS_SCRIPT .sh)
validateArgs "$@"


if [ $# -eq 0 ]
	then
		echo "ERROR: No option/switches supplied to function!"
		showHelp
		exit 1
	fi

echo "FUNCTION_NAME"=$FUNCTION_NAME
if [ -z $FUNCTION_NAME ]; then
	echo "ERROR: Required variables have not been set!"
	echo "Please enter a value for FUNCTION_NAME, then try again!"
	exit 1
fi
echo "END: Environment variables:"


ResourceNotFoundException() {
	echo "ERROR TYPE: ResourceNotFoundException"
	echo "ERROR REASON: Lambda function:["${FUNCTION_NAME}"], does not exist"
}


CMD=" aws lambda list-functions --query ""Functions[?FunctionName=='${FUNCTION_NAME}'].FunctionName"" --output text"
echo "CMD="$CMD
FUNCTION_EXISTS=$($CMD)
echo "FUNCTION_EXISTS="$FUNCTION_EXISTS

if [ -z "${FUNCTION_EXISTS}" ]; then
	echo "Nothing to do, Lambda function:"[$FUNCTION_NAME]" does not exist in AWS."
	exit 1
else
	echo "** In Delete Section **"
	echo "Lambda Function:[${FUNCTION_NAME}], exists, deleting.."
	$(aws lambda delete-function --function-name ${FUNCTION_NAME}) || ResourceNotFoundException

fi 


if [ ! -z $PURGE_FILE ]; then
	
	
	if [ ! -f $PURGE_FILE ]; then
		echo "File:[$PURGE_FILE] not found!"
	else
		echo "File:[$PURGE_FILE], exists"
		echo "Executing file..."
		source ./$PURGE_FILE
	fi
fi

