#!/bin/bash
###########################################################################
#
# Script        : test.sh
# Purpose       : Test a deployed AWS Lambda function
# Authors       : Steve Robinson - The MiddlewareShop (http://www.themiddlewareshop.com)
# Created       : April 2016 for DevOps course
# 
# History
# date           ver  who  what 
# ----           ---  ---  ----
# 18-April-2016  0.1  scr  Updated the first version to new format
#
OUTFILE=test.txt
<<<<<<< HEAD

##########################################################################
#
# showUsage() - display a simple usage message
#
##########################################################################
showUsage() {
    echo "Usage: ${0##*/} -n <Enter function name e.g myfunc1>"
    exit 1
}
 
##########################################################################
#
# validateArgs() - parameter validation
#
##########################################################################
validateArgs() 
{ 
    
    while getopts ":n:"  opt; do
        echo "\$opt=$opt$, \$OPTIND=$OPTIND, \$OPTARG=$OPTARG"
        case $opt in
       
        n)  export FUNCTION_NAME="${OPTARG}"
	        ;;
            

		\?) echo "No option specified"
			;;
 
        *)  echo "Invalid option -${OPTARG}">&2
            showUsage
			exit 0
            ;;
 
		esac
    done
 
    shift $((OPTIND - 1))
 
    if [ $# -ne 0 ]
    then
        showUsage
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

echo "FUNCTION_NAME"=$FUNCTION_NAME
=======
FUNCTION_NAME=myfunc1
>>>>>>> 0b39dc81c8b2327f23daf4fd42e59eda3a88375a
if [ -z $FUNCTION_NAME ]; then
	echo "ERROR: Required variables have not been set!"
	echo "Please enter a value for FUNCTION_NAME, then try again!"
	exit 1
fi
echo "END: Environment variables:"
rm -Rf $OUTFILE
aws lambda invoke \
    --function-name $FUNCTION_NAME \
	$OUTFILE
echo
echo "Output of the lambda function is:"
cat $OUTFILE
echo
