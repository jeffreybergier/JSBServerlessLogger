const crypto = require('crypto');
const aws = require('aws-sdk');
const ses = new aws.SES({region: 'us-east-2'});
const kSecretKey = process.env.SECRET;
const kEmailFrom = process.env.EMAIL_FROM;
const kEmailTo   = process.env.EMAIL_TO;

exports.handler = async (event, context, callback) => {
  // check environment variable
  if (!(typeof kSecretKey === 'string' 
     && typeof kEmailFrom === 'string'
     && typeof kEmailTo   === 'string'))
  {
    return { statusCode: 403, body:'' };
  }
  // check make sure request is right
  if (event.requestContext.http.method != "PUT") {
    return { statusCode: 403, body:'' };
  }
  if (event.requestContext.http.path != "/log.cgi") {
    return { statusCode: 403, body:'' };
  }
  if (!('mac' in event.queryStringParameters)) {
    return { statusCode: 403, body:'' };
  }
  
  try {
    // do HMAC signature verification
    const secretKey = Buffer.from(kSecretKey, 'base64');
    const requestBody = Buffer.from(event.body, 'base64');
    const lhsSignatureB64 = event.queryStringParameters.mac.replace(' ', '+');
    const rhsSignature = crypto
                            .createHmac('sha256', secretKey)
                            .update(requestBody)
                            .digest();
    const rhsSignatureB64 = Buffer.from(rhsSignature, 'binary').toString('base64');
    if (lhsSignatureB64 != rhsSignatureB64) {
      return { statusCode: 403, body:'' };
    }
    
    // compose email
    const requestEvent = JSON.parse(requestBody);
    const functionName = requestEvent["logDetails"]["functionName"];
    const filePath = requestEvent["logDetails"]["fileName"];
    var fileName;
    try {
      // attempt to get just the last path component out of this string
      fileName = filePath.substring(filePath.lastIndexOf('/') + 1);
    } catch(error) {
      fileName = filePath;
    }
    const emailSubject = '[' + requestEvent["incident"] + '] ' + fileName + ' - ' + functionName;
    const emailBody = JSON.stringify(requestEvent, null, '    '); // Pretty print with 4 spaces
    
    // send email
    const params = { Destination: { ToAddresses: [kEmailTo] },
                     Message: { Body: { Text: { Data: emailBody } },
                                Subject: { Data: emailSubject } },
                     Source: kEmailFrom };

    const request = ses.sendEmail(params);
    await request.promise()
    return { statusCode: 200, body:'SUCCESS' };
  } catch(error) {
    return { statusCode: 403, body:'' };
    // debugging
    // return { statusCode: 400, body:error.message };
  }
  // Debugging
  // return { statusCode: 400, body:JSON.stringify(event) };
};
