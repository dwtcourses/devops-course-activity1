## Cleanup
## This script is called by delete.sh when it is passed a file-name using the -a <file_name> param
## It is created to clean up after testing or as a reset after labs are complete.
CALLING_SCRIPT=${0##*/}
echo "Calling Script="$CALLING_SCRIPT
## me=`basename "$0"`
## echo "me=$me"
echo "Cleaning up..."
rm -f myfunc*-assume-role-policy.json
rm -f myfunc*.js