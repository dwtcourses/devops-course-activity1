#!/bin/bash
###########################################################################
#
# Script        : delete.sh
# Purpose       : Delete an API Gateway.
# Authors       : Steve Robinson - http://www.blueboxblue.com steve@blueboxblue.com
# Created       : April 2018 for DevOps course
# 
# History
# date           ver  who  what 
# ----           ---  ---  ----
# 19-April-2018  0.1  scr  Updated the first version to new format
# 01-May-2018    0.2  scr  Finalised and tested
#
# Comments: 
# Should add region as a commnad-line input, and if null use a default region?

VERSION=0.2

##########################################################################
#
# showHelp() - display full help
#
##########################################################################
showHelp() {

    echo "Usage: ${0##*/} -n <Enter API Gateway name e.g myapigw1>"
    echo 
    echo "Delete API Gateway"
    echo "Options:"
    echo "  -n           Delete API Gateway name"
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
       
        n)  export API_NAME="${OPTARG}"
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

############################################################
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
	
echo "API_NAME=${API_NAME}"

## Setup (fixed variables)
REGION="eu-west-1"

##Get the API ID
API_ID=$(aws apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" \
--output text --region ${REGION})
echo "API_ID=[$API_ID]"

if [ -z "$API_ID" ]; then
	echo "REST API using name:[${API_NAME}], does not exist!, exiting."
	exit 1
else
	##delete-rest-api
	##--rest-api-id <value>
	##[--cli-input-json <value>]
	##[--generate-cli-skeleton <value>]

	echo "Deleting REST-API API_ID=[$API_ID]"
	CMD="aws apigateway delete-rest-api --rest-api-id ${API_ID}"
	echo "CMD="$CMD
	echo "Executing command..."
	$($CMD)
	
	API_ID=$(aws apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" \
	--output text --region ${REGION})
	echo "API_ID=[$API_ID]"
	if [ -z "$API_ID" ]; then
		echo "SUCCESS: REST API using name:[${API_NAME}], confirmed deleted!"
		exit 0
	else
		echo "ERROR: REST API using name:[${API_NAME}], still exists!"
		exit 1
	fi
fi


#delete-integration
#--rest-api-id <value>
#--resource-id <value>
#--http-method <value>
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]

#delete-method
#--rest-api-id <value>
#--resource-id <value>
#--http-method <value>
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]

#delete-resource
#--rest-api-id <value>
#--resource-id <value>
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]


#delete-method-response
#--rest-api-id <value>
#--resource-id <value>
#--http-method <value>
#--status-code <value>
#[--cli-input-json <value>]
#[--generate-cli-skeleton <value>]


#aws apigateway delete-integration --rest-api-id 1234123412 --resource-id a1b2c3 --http-method GET
#aws apigateway delete-method --rest-api-id 1234123412 --resource-id a1b2c3 --http-method GET
#aws apigateway delete-resource --rest-api-id 1234123412 --resource-id a1b2c3
#aws apigateway delete-method-response --rest-api-id 1234123412 --resource-id a1b2c3 --http-method GET --status-code 200