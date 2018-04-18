#!/bin/bash
# Created by Steve Robinson 18-04-2018 steve@blueboxblue.com
# This script will install the AWS CLI
# Requires python3, python3-pip


sudo apt-get update -yq


read -rp "Install and Configure AWS CLI? (y/n) " INSTALL
if [[ $INSTALL =~ ^([yY][eE][sS]|[yY])$ ]]; then

	# Test if pip is installed
	command -v pip >/dev/null 2>&1 || {
		echo "Installing Python pip3..."
		sudo apt-get install python3 python3-pip -yq
		pip3 --version
		
	}
	
	# Test if AWS CLI is installed
	command -v aws >/dev/null 2>&1 || {
		
		echo "Installing zip..."
		sudo apt-get install zip -yq
		echo "Installing ntp to ensure clock is in sync for awscli"
		sudo apt-get install ntp -yq
		sudo service ntp start
		echo "Installing awscli..."
		pip3 install awscli --upgrade --user && echo; echo "Installed awscli."

		aws configure
		complete -C '/usr/local/bin/aws_completer' aws
	} && {
		echo "Updating awscli..."
		pip3 install awscli --upgrade --user && echo; echo "Updated awscli."
	}

	echo "Completed."
fi