class ServerLink {
  static const String mainServerURL = 'https://app.worxsafety.com.au';

  //URL Link list
  static const String newSessionURL = '${ServerLink.mainServerURL}/qr-login/';  // + {uuid} - Generate uuid session token
  static const String authenticateURL = '${ServerLink.mainServerURL}/api/authenticate_app';  // payload {tablet_setup_code,device_name} - post to server with token for log in

  static const String fetchVisitorSites = '${ServerLink.mainServerURL}/api/visitor/sites'; // get sites payload {token}
  static const String fetchVisitorContacts = '${ServerLink.mainServerURL}/api/visitor/contacts'; // get contacts  payload {token}
  static const String fetchVisitorClient = '${ServerLink.mainServerURL}/api/visitor/client'; // get clients payload {token}

  static const String fetchVisitorQuestions = '${ServerLink.mainServerURL}/api/visitor/site_questions'; // post  {"site_id": }
  static const String sendSMS = '${ServerLink.mainServerURL}/api/visitor/send_sms'; // post {"user_id": "23", "mobile":"0422502693","message": "this is a test message"}
  static const String sendEmail = '${ServerLink.mainServerURL}/api/visitor/send_email'; // post {"user_id" ： 23， "name":"fullname", "email":"required email", "phone":"text", "message":"text"}

  // post {"!site_id":"",!"name":"","!email":"","organisation":"","phone":"","!questions":"{reference to bottom}"}
  ///questions
  static const String pushVisitorSignInLedge = '${ServerLink.mainServerURL}/api/visitor/sign_in';
  //sign in responses:
  ///success: 'messsage' => 'Login Complete',  'visitor_id' => $uniqueId
  ///error: 'message' => 'Evacuate'
  ///error: 'error' => 'Signed In already'
  static const String pushVisitorSignOutLedge = '${ServerLink.mainServerURL}/api/visitor/sign_out'; // post {"visitor_id":"23"}
  static const String revokeVisitorToken = '${ServerLink.mainServerURL}/api/visitor/revoke'; // post header only
}

//--------------------------Sign in Question Format------------------------------------------
/* default questions: 
I have been advised of the required minimum PPE for this site. 

Observe all safety signage, read and follow site rules & instructions of the Site Supervisor. 

Not smoke on site except in Designated Areas. 

Be escorted by an authorised Pink Batteries representative at all times. 

In the event of fire or emergency evacuation, follow the instructions of Pink Batteries representative. 

Report any incidents / accident immediately.

default form:
{
  "name": "Travis McLean ",
  "email": "travis.mclean@newheightsplumbing.com.au",
  "organisation": "New Heights Plumbing ",
  "phone": "0439028167",
  "inductions": [],
  "agree": {
    "1": true,
    "2": true,
    "3": true,
    "4": true,
    "5": true,
    "6": true
  },
  "unique_id": "VIS69363c49e713a"
}
*/

/*
customized sign in question
{
  "name": "Jake G Harris",
  "email": "jakeh@harleydykstra.com.au",
  "organisation": "Harley Dykstra",
  "phone": "0428837763",
  "inductions": [],
  "agree": {
    "sign_form_id": 71,
    "project_question": [
      "Yes",
      "Yes",
      "Yes",
      "Yes",
      "Yes",
      "Yes",
      "Yes"
    ],
    "questions": [
      {
        "name": "1",
        "question": "I have been informed of and understand the hazards associated with this site, including but not limited to moving plant, uneven ground, noise, dust, and other construction activities"
      },
      {
        "name": "2",
        "question": "I will NOT be performing any tasks/whilst onsite"
      },
      {
        "name": "3",
        "question": "I have received and understand the site safety rules, emergency procedures, and any instructions relevant to my visit"
      },
      {
        "name": "4",
        "question": "I will comply with all reasonable directions given by site management and wear the required personal protective equipment (PPE) at all times"
      },
      {
        "name": "5",
        "question": "I will not enter any restricted areas unless authorised and accompanied by an authorised person"
      },
      {
        "name": "6",
        "question": "I accept responsibility for my own actions while on site and understand that failure to follow site rules may result in removal from the premises"
      },
      {
        "name": "7",
        "question": "I will conduct myself in a manner that does not place myself or others at risk"
      }
    ]
  },
  "unique_id": "VIS693611ca241d7"
}
*/