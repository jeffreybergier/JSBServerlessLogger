//
//  Created by Jeffrey Bergier on 2020/08/24.
//
//  MIT License
//
//  Copyright (c) 2020 Jeffrey Bergier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//

const crypto = require('crypto');
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const ses = new SESClient({ region: "us-east-2" });
const DEBUG = process.env.DEBUG_MODE === 'DEBUG';
const kSecretKey = process.env.SECRET;
const kEmailFrom = process.env.EMAIL_FROM;
const kEmailTo   = process.env.EMAIL_TO;

exports.handler = async (event, context, callback) => {
  // check environment variable
  if (!(typeof kSecretKey === 'string'
     && typeof kEmailFrom === 'string'
     && typeof kEmailTo   === 'string'))
  {
    if (DEBUG) { return { statusCode: 410, body:'KEYS MISSING' };
    } else { return { statusCode: 403, body:'' }; }
  }
  // check make sure request is right
  if (event.requestContext.http.method != "PUT") {
    if (DEBUG) { return { statusCode: 409, body:'WRONG HTTP TYPE' };
    } else { return { statusCode: 403, body:'' }; }
  }
  if (event.requestContext.http.path != "/log.cgi") {
    if (DEBUG) { return { statusCode: 408, body:'WRONG ENDPOINT' };
    } else { return { statusCode: 403, body:'' }; }
  }
  if (!('mac' in event.queryStringParameters)) {
    if (DEBUG) { return { statusCode: 407, body:'MISSING MAC SIGNATURE' };
    } else { return { statusCode: 403, body:'' }; }
  }

  try {
    // do HMAC signature verification
    const secretKey = Buffer.from(kSecretKey, 'base64');
    const requestBody = Buffer.from(event.body, 'base64');
    const lhsSignatureB64 = event.queryStringParameters.mac.replace(/\s/g, '+');
    const rhsSignature = crypto
                            .createHmac('sha256', secretKey)
                            .update(requestBody)
                            .digest();
    const rhsSignatureB64 = Buffer.from(rhsSignature, 'binary').toString('base64');
    if (lhsSignatureB64 != rhsSignatureB64) {
        if (DEBUG) { return { statusCode: 406, body:'SIGNATURE MISMATCH' };
        } else { return { statusCode: 403, body:'' }; }
    }
    try {
        // compose email
        const requestEvent = JSON.parse(requestBody);
        const functionName = requestEvent["logDetails"]["functionName"];
        const fileName = requestEvent["logDetails"]["fileName"];
        const emailSubject = '[' + requestEvent["incident"] + '] ' + fileName + ' - ' + functionName;
        const emailBody = JSON.stringify(requestEvent, null, '    '); // Pretty print with 4 spaces

        // send email
        const params = { Destination: { ToAddresses: [kEmailTo] },
                         Message: { Body: { Text: { Data: emailBody } },
                                    Subject: { Data: emailSubject } },
                         Source: kEmailFrom };
        const command = new SendEmailCommand(params);
        await ses.send(command);
        return { statusCode: 200, body:'SUCCESS' };
    } catch(error) {
        if (DEBUG) { return { statusCode: 404, body:'ERROR SENDING EMAIL' };
        } else { return { statusCode: 403, body:'' }; }
    }
  } catch(error) {
      if (DEBUG) { return { statusCode: 405, body:'ERROR GENERATING SIGNATURE' };
      } else { return { statusCode: 403, body:'' }; }
  }
};
