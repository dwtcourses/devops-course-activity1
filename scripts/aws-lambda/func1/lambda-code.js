exports.handler = function(event, context, callback) {
    console.log("event: ", JSON.stringify(event, null, 4));
    let responseCode = 200;

	var firstName = process.env.FIRST_NAME; 
	var lastName = process.env.LAST_NAME; 
	var fullName=(firstName + ' ' + lastName);
	var mesgText=("Hello:" + fullName);
	
	var responseBody = {
        message: mesgText
    };
	
    var response = {
        statusCode: responseCode,
        body: JSON.stringify(responseBody)
    };
    console.log("response: " + JSON.stringify(response))
    callback(null, response);
	
	context.succeed();
 }