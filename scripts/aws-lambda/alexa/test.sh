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
# 18-April-2018  0.1  scr  Updated the first version to new format
# 04-May-2018    0.2  scr  Updated to use function name as the output file.
#
VERSION=0.2
##########################################################################
#
# showHelp() - display full help
#
##########################################################################
showHelp() {

    echo "Usage: ${0##*/} -n <Enter function name e.g myfunc1>"
    echo 
    echo "Invoke Lamda Function"
    echo "Options:"
    echo "  -n           Lambda function by name"
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
    
    while getopts ":h:n:"  opt; do
        echo "\$opt=$opt$, \$OPTIND=$OPTIND, \$OPTARG=$OPTARG"
        case $opt in
       
        n)  export FUNCTION_NAME="${OPTARG}"
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
OUTFILE=$FUNCTION_NAME.txt
echo $OUTFILE

echo "Purging previous test result..."
rm -Rf $OUTFILE
echo "Invoking Lambda function [$FUNCTION_NAME]..."
aws lambda invoke \
    --function-name $FUNCTION_NAME \
	$OUTFILE
echo
echo "Output of the lambda function is:"
cat $OUTFILE
echo
