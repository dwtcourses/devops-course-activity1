source ./variables.sh
lambda_function_name=$FUNCTION_NAME
role_name="$lambda_function_name-role" 
aws iam delete-role --role-name "$role_name"