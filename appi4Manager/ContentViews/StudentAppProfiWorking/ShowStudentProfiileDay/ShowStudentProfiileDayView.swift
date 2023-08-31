//
//  ShowStudentProfiileDayView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/16/23.
//

import SwiftUI


struct ShowStudentProfiileDayView: View {
    
    @State private var selectedIndex = 0
    @State private var selectedDay: String = "Sunday"
    let days = ["Sunday", "Monday", "Tuesday"]

    
    //  MARK: -  Properties
    @ObservedObject     var studentAppProfileViewModel =    StudentAppProfileViewModel()
    @EnvironmentObject  var appxViewModel:                  AppxViewModel
    @State              var currentProfile:                 StudentAppProfile
    @State              var dayProfile:                     DailySessions? = nil
    @State 				var	dayOfWeekString:				String = "Sunday"
    
    // to control the Load
    @State private var hasError = false
    @State private var error: ApiError?
    @State private var showApps: Bool = false

    // Temp To test stuff
    @State var appListStringAM: Array<String> = []
    @State var appListStringPM: Array<String> = []
    @State var appCodexAM: Int = 0
    @State var appCodexPM: Int = 0
    
    
    
    @State var dailySessionConfigurationx: [DailySessionConfiguration] =
    Array(repeating: DailySessionConfiguration(
        oneAppLockAM: false,
        appCodeAM: 0,
        sessionLengthAM: 0,
        sessionLengthDoubleAM: 0.0,
        oneAppLockPM: false,
        appCodePM: 0,
        sessionLengthPM: 0,
        sessionLengthDoublePM: 0.0
    ), count: 7)
    @State var theDayNumber: Int = 0 {
        didSet {
            upDateDailySessionConfiguration()
        }
    }
    
//    @State var singleAppMode
    
    @State var studentAppProfilesList: [StudentAppProfile]

//	properties to communicate with disclosure app and group box
    
    
    @State var oneAppLockAM: Bool = false
    @State var oneAppLockPM: Bool = false
    
    @State var appListAM = ""
    @State var appListPM = ""
    
    @State var appCodeAM = 0
    @State var appCodePM = 0

    @State var sessionLengthAM = 0
    @State var sessionLengthPM = 0

    
    @State private var isSheetPresentedAM = false
    @State private var isSheetPresentedPM = false

    @State private var selectedSession: Session?
    
    
    var body: some View {
        ScrollView {
        VStack {
            HStack {
                Button("Sunday") {
                    dayOfWeekString = "Sunday"
                    theDayNumber = 0
                }
                Button("Monday") {
                    dayOfWeekString = "Monday"
                    theDayNumber = 1
                }
                Button("Tuesday") {
                    dayOfWeekString = "Tuesday"
                    theDayNumber = 2
                }
            }
            
            Text("Selected day: \(dayOfWeekString)")
                        
            VStack(alignment: .leading, spacing: 12) {

                SessionGroupView(selectedNum:       0.0,
                                 timeOfDay:         "**AM:** - 9:00 - 11:59",
                                 sessionLength:     $dailySessionConfigurationx[theDayNumber].sessionLengthAM,
                                 iPadLockedIntoApp: $dailySessionConfigurationx[theDayNumber].oneAppLockAM,
                                 seesionNumber:     0,
                                 appList:           $appListAM,
                                 isSheetPresented:  $isSheetPresentedAM,
                                 
                                 appCodeAM:         $dailySessionConfigurationx[theDayNumber].appCodeAM,
                                 sessionLengthDoubleAM: $dailySessionConfigurationx[theDayNumber].sessionLengthDoubleAM)
 
                SessionGroupView(selectedNum:       0.0,
                                 timeOfDay:         "**PM:** - 9:00 - 11:59",
                                 sessionLength:     $dailySessionConfigurationx[theDayNumber].sessionLengthPM,
                                 iPadLockedIntoApp: $dailySessionConfigurationx[theDayNumber].oneAppLockPM,
                                 seesionNumber:     0,
                                 appList:           $appListPM,
                                 isSheetPresented:  $isSheetPresentedPM,
                                 
                                 appCodeAM:         $dailySessionConfigurationx[theDayNumber].appCodePM,
                                 sessionLengthDoubleAM: $dailySessionConfigurationx[theDayNumber].sessionLengthDoublePM)

                .padding(.bottom)
            }
            .frame(width: 340)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding()
            
        }
    }
        
//  MARK: - OnAppear
        .onAppear {
            Task {
                if appxViewModel.ignoreLoading {
                // Don't load the classes if ignoreLoading is true
                    appxViewModel.ignoreLoading = false
                } else {
                // Load the classes if ignoreLoading is false
                    await loadTheapps()
                    appxViewModel.ignoreLoading = false
                }
            }
            // load the current profile into pieces
            guard let xoneAppLockAM = currentProfile.sessions[dayOfWeekString]?.amSession.oneAppLock else { fatalError("one app lock failed") }
            oneAppLockAM = xoneAppLockAM
            
            
            // load it to regular data
            if let returnedSession = selectedSession,
               let theapp = returnedSession.apps.first {
                print("##-##", theapp)
                selectedSession = nil
            } else {
                print("returned is nill")
            }

            upDateDailySessionConfiguration()
            studentAppProfileViewModel.profiles = studentAppProfilesList
        }
 

//  MARK: -  OnChange ViewModel is Loaded
        .onChange(of: appxViewModel.isLoaded) { isDataLoaded in
            if isDataLoaded {
                processApps()
            }
        }

//  MARK: -  OnChange ViewModel is Loaded

        .sheet(isPresented: $isSheetPresentedAM) {
            CategoryDisclosureView(selectedSession: $selectedSession,
                                   isSheetPresented: $isSheetPresentedAM,
                                   lengthOfSesssion: $dailySessionConfigurationx[theDayNumber].sessionLengthAM,
                                   singleAppMode: $dailySessionConfigurationx[theDayNumber].oneAppLockAM,
                                   appCode: $dailySessionConfigurationx[theDayNumber].appCodeAM)
                .onDisappear {
                    if let returnedSession = selectedSession,
                       let theapp = returnedSession.apps.first {
                        updateTheStudentAM(theapp, returnedSession)
                       
                    } // end if
         
                } // end onDisappear
        } // end sheet

        .sheet(isPresented: $isSheetPresentedPM) {
            CategoryDisclosureView(selectedSession: $selectedSession,
                                   isSheetPresented: $isSheetPresentedPM,
                                   lengthOfSesssion: $dailySessionConfigurationx[theDayNumber].sessionLengthPM,
                                   singleAppMode:    $dailySessionConfigurationx[theDayNumber].oneAppLockPM,
                                   appCode:          $dailySessionConfigurationx[theDayNumber].appCodePM)
                .onDisappear {
                    if let returnedSession = selectedSession,
                       let theapp = returnedSession.apps.first {
                        updateTheStudentPM(theapp, returnedSession)
                       
                    } // end if
         
                } // end onDisappear
        } // end sheet
    }
}

extension ShowStudentProfiileDayView {
    
//  MARK: -  Update the student profile
    
    func updateTheStudentAM(_ theapp: Int, _ returnedSession: Session) {
        
        // get the dayOfWeek from current Profile
        guard var dayOfWeekSession = currentProfile.sessions[dayOfWeekString]  else {
            fatalError("could nor get the day")
        }
        
        dump(returnedSession)
        dayOfWeekSession.amSession = returnedSession
        
        studentAppProfileViewModel.profiles = studentAppProfilesList
        
        if let idx = studentAppProfileViewModel.profiles.firstIndex(where: { prf in
            prf.id == 8
        }) {
           
            var studentProf = studentAppProfileViewModel.profiles[idx]
            studentProf.replaceSession(forDay: dayOfWeekString , with: dayOfWeekSession)
            dump(studentProf)
                // 5
            studentAppProfileViewModel.profiles[idx] = studentProf
                //6
            dump(studentAppProfileViewModel.profiles[idx])
            
//            currentProfile.sessions.removeValue(forKey: dayOfWeekString)
            currentProfile.sessions.updateValue(dayOfWeekSession, forKey: dayOfWeekString)
            
            dump(currentProfile.sessions[dayOfWeekString])
           
          
            upDateDailySessionConfiguration()
            
            studentAppProfileViewModel.saveProfiles()
            
            studentAppProfilesList = studentAppProfileViewModel.profiles
            
        } else {
            print("no match")
        }
    }
    
    func updateTheStudentPM(_ theapp: Int, _ returnedSession: Session) {
        
        print(theapp)
        print(returnedSession.oneAppLock)
        print(returnedSession.sessionLength)
        
        currentProfile.sessions[dayOfWeekString]?.pmSession = returnedSession
        
        if  let theapp = currentProfile.sessions[dayOfWeekString]?.pmSession.apps.first {
            print(theapp)
        }
        
        print(currentProfile.sessions[dayOfWeekString]?.pmSession.oneAppLock)
        print(currentProfile.sessions[dayOfWeekString]?.pmSession.sessionLength)
        
        
        studentAppProfileViewModel.profiles = studentAppProfilesList
        
        if let idx = studentAppProfileViewModel.profiles.firstIndex(where: { prf in
            prf.id == 8
        }) {
                // 5
            studentAppProfileViewModel.profiles[idx] = currentProfile
                //6
            studentAppProfileViewModel.saveProfiles()
             studentAppProfilesList = studentAppProfileViewModel.profiles
            
        } else {
            print("no match")
        }
    }
    
    func upDateDailySessionConfiguration() {
        guard let theAMSession                                          = currentProfile.sessions[dayOfWeekString]?.amSession else {fatalError("dd")}

        dailySessionConfigurationx[theDayNumber].sessionLengthAM        = theAMSession.sessionLength
        dailySessionConfigurationx[theDayNumber].sessionLengthDoubleAM  = Double(theAMSession.sessionLength)
        dailySessionConfigurationx[theDayNumber].oneAppLockAM           = theAMSession.oneAppLock
        
        if let theOneApp                                                = currentProfile.sessions[dayOfWeekString]?.amSession.apps.first {
            dailySessionConfigurationx[theDayNumber].appCodeAM          = theOneApp
        }
        
        guard let thePMSession                                          = currentProfile.sessions[dayOfWeekString]?.pmSession else {fatalError("dd")}

        dailySessionConfigurationx[theDayNumber].sessionLengthPM        = thePMSession.sessionLength
        dailySessionConfigurationx[theDayNumber].sessionLengthDoublePM  = Double(thePMSession.sessionLength)
        dailySessionConfigurationx[theDayNumber].oneAppLockPM           = thePMSession.oneAppLock
        
        if let theOneApp                                                = currentProfile.sessions[dayOfWeekString]?.pmSession.apps.first {
            dailySessionConfigurationx[theDayNumber].appCodePM          = theOneApp
        }
    }
    

    func processApps() {

        guard let amApps = currentProfile.sessions[dayOfWeekString]?.amSession.apps else { fatalError("Big Error") }
        print("----",amApps)
        for appCode in amApps {
            if let appName = getAppWithId(appCode)?.name {
                appCodexAM = appCode
                appListStringAM.append(appName)
            }
        }
        print(currentProfile.sessions[dayOfWeekString]?.pmSession.apps)
        guard let pmApps = currentProfile.sessions[dayOfWeekString]?.pmSession.apps else { fatalError("Big Error") }
        for appCode in pmApps {
            if let appName = getAppWithId(appCode)?.name {
                appCodexPM = appCode
                appListStringPM.append(appName)
            }
        }
    }
    
// really need to get app with icon
    func getAppWithId(_ appId: Int) -> Appx? {
        
        do {
            let app = try appxViewModel.getAppWith(appId)
            return app
            // Use the app here
        } catch AppError.appNotFound {
            print("App with the given ID was not found.")
            return nil
        } catch {
            print("An unknown error occurred.")
            return nil
        }
    }
    
    func getAppNameWithId(_ appId: Int?) -> String? {
        guard let appId = appId else {return nil}
        do {
            let app = try appxViewModel.getAppWith(appId)
            return app.name
            // Use the app here
        } catch AppError.appNotFound {
            print("App with the given ID was not found.")
            return nil
        } catch {
            print("An unknown error occurred.")
            return nil
        }
    }

    
 func loadTheapps() async {
     print("in load apps")
     do {
         try await appxViewModel.loadData2()
     } catch  {
         if let xerror = error as? ApiError {
             self.hasError   = true
             self.error      = xerror
         }
     }
 }
 
}
