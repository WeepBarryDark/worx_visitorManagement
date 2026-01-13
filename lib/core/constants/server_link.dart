class ServerLink {
  static const String mainServerURL = 'https://app.worxsafety.com.au';

  //URL Link list
  static const String newSessionURL = '${ServerLink.mainServerURL}/qr-login/';  // + {uuid} - Generate uuid session token - scan with phone to create session
  static const String authenticateURL = '${ServerLink.mainServerURL}/api/authenticate_app';  // post - payload {tablet_setup_code,device_name} - post to server with token for log in

  static const String fetchVisitorSites = '${ServerLink.mainServerURL}/api/visitor/sites'; // get sites  {token}
  static const String fetchVisitorContacts = '${ServerLink.mainServerURL}/api/visitor/contacts'; // get contacts  {token}
  static const String fetchVisitorClient = '${ServerLink.mainServerURL}/api/visitor/client'; // get clients  {token} 

  static const String fetchVisitorQuestions = '${ServerLink.mainServerURL}/api/visitor/site_questions'; // post  {token}{"site_id": }
  static const String sendSMS = '${ServerLink.mainServerURL}/api/visitor/send_sms'; // post {token}{"user_id": "23", "mobile":"0422502693","message": "this is a test message"}
  static const String sendEmail = '${ServerLink.mainServerURL}/api/visitor/send_email'; // post {token}{"user_id" ： 23， "name":"fullname", "email":"required email", "phone":"text", "message":"text"}

  static const String pushVisitorSignOutLedge = '${ServerLink.mainServerURL}/api/visitor/sign_out'; // post {token}{"visitor_id":"23"}
  static const String revokeVisitorToken = '${ServerLink.mainServerURL}/api/visitor/revoke'; // post {token}{'device_name': finalDeviceName},

  //Continue------------------------------------------------
  static const String pushVisitorSignInLedge = '${ServerLink.mainServerURL}/api/visitor/sign_in'; //post -push kiosk signed-in visitor to server
  // post {token}{"site_id":"","name":"","email":"","organisation?":"","phone?":"","questions":"{reference to bottom}","visitor_photo"："base64 code"} -> example at below
  // add new feature visitor_photo for feature 10
  //sign in responses:
  ///success: 'messsage' => 'Login Complete',  'visitor_id' => $uniqueId
  ///error: 'message' => 'Evacuate'
  ///error: 'error' => 'Signed In already'
  
  static const String fetchSignedInvisitor = '${ServerLink.mainServerURL}/api/visitor/site_visitors'; // post - {token}{"site_id": } for feature 2
  static const String fetchUserQrLink = '${ServerLink.mainServerURL}/api/user/sign_in_link'; // post - {token}{"site_id": } for feature 5 - return slug included link
  
  static const String pushDeliveryInLedge = '${ServerLink.mainServerURL}/api/delivery'; // post - {token}{"deliveryCompany":"","notificationSent":"" } for feature 6 

}

//--------------------------Sign in Question Format------------------------------------------

/* 
visitor 
[{"id":319110,"project_id":1,"name":"Visitor - test 123","email":"test@qq.com","company":"544","phone":"1234145","visitor_id":"VIS69657fde76e08","project_name":"1002567 Thirroul Development - Alternate Loc 1002567 Thirroul Development - Alternate Loc","sign_in":"2026-01-12T23:12:30+00:00","sign_out":""},{"id":319130,"project_id":1,"name":"Visitor - barrys","email":"hshu@qq.com","company":"hssj","phone":"0416166166","visitor_id":"VIS696584f335898","project_name":"1002567 Thirroul Development - Alternate Loc 1002567 Thirroul Development - Alternate Loc","sign_in":"2026-01-12T23:34:11+00:00","sign_out":""},{"id":319237,"project_id":1,"name":"Visitor - test","email":"tsst@qq.com","company":"","phone":"","visitor_id":"VIS6965a32767349","project_name":"1002567 Thirroul Development - Alternate Loc 1002567 Thirroul Development - Alternate Loc","sign_in":"2026-01-13T01:43:03+00:00","sign_out":""},{"id":319239,"project_id":1,"name":"Visitor - wast bar","email":"tesf@qq.com","company":"","phone":"","visitor_id":"VIS696

Client 

Client data: {"logo":"https://storage.worxsafety.com.au/site/public/22080/pblogo.svg","background_image":"https://storage.worxsafety.com.au/site/public/7/60dbb67c245b3_bg-masthead.jpg","slug":"pinkbatteries","name":"HUGH ARTHUR TORNEY","trading_name":"Pink Batteries"}

Logic: if it is default question - return 1. default quest, otherwise, it is the customized question - return 2. customized sign in question
//-----------------------------
default questions: 
I have been advised of the required minimum PPE for this site. 

Observe all safety signage, read and follow site rules & instructions of the Site Supervisor. 

Not smoke on site except in Designated Areas. 

Be escorted by an authorised {$clientName}  representative at all times. 

In the event of fire or emergency evacuation, follow the instructions of {$clientName} representative. 

Report any incidents / accident immediately.
//----------------------------------

1. default quest:
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
2. customized sign in question
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