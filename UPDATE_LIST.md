Priority: 
1. Search option Person Visiting, as well as when choosing from list on sign out
A: Done
2. import signed in visitors, so allowing sign out from any kiosk, not necessarily the one they signed in on
A: Hold, an API is required for this feature.
3. ability for 2 (or more) kiosks to be connected to same printer (print queue)
A: Done, Visitors are now able to see the print status in real time.
4. resolve issue with different paper making printing fail - we have 2 types of paper to test! 
A: Done, the user can now select paper type and test print after the printer is connected.
5. Existing user sign-in option (Have option in settings to show site specific qr code or have Contractor/Employee option) https://www.worxsafety.com.au/demo-sitesignin/
A: Hold, required client Slug API.
6. log deliveries in Site ledger
A: Hold, an API is required for this featur.
7. Check app doesnt go to sleep, also if you can restrict closing it, or opening another app (this might be an ipad setting, not an app setting). 
A:Done, dependencies: doesn't work in ios
    1.Package: wakelock_plus: ^1.2.8 (pubspec.yaml:33)
    2.Service: KioskModeService (lib/services/kiosk_mode_service.dart)


Next in queue: 
8. Save previous selections in Admin side (At the moment have to update each time)
A:Done, storaged when confirm first time, it will be reset when log out.
9. bulk visitor upload - ability to upload a csv into web app, then have an option on kiosk app to choose from pre-loaded visitor list. Click on your name, then it will sign you in and print a sticker.
A: awaiting confirm


Nice to have: 
10. option to take photos of workers
A: Done.