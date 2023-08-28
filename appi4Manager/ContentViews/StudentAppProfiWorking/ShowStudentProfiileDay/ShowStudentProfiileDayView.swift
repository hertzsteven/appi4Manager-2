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
    
    fileprivate func updateTheStudentAM(_ theapp: Int, _ returnedSession: Session) {
        
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
    
    fileprivate func updateTheStudentPM(_ theapp: Int, _ returnedSession: Session) {
        
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
    
    var body: some View {
        
            //        Picker("Select a day", selection: $selectedIndex) {
            //            ForEach(0..<days.count) { index in
            //                Text(self.days[index]).tag(index)
            //            }
            //        }
            //        .pickerStyle(.menu)
            //        .onChange(of: selectedIndex) { newValue in
            //            selectedDay = days[newValue]
            //            dayOfWeekString = days[newValue]
            //        }
        
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
            
            
/* 
            Text("Sam Ashe - App Profile").padding([.top, .bottom], 16)
            
            
            Text("lock to one app \(oneAppLockAM ? "yes" : "No")")
            
            if let sessionLength = currentProfile.sessions[dayOfWeekString]?.amSession.sessionLength {
                Text("length: \(sessionLength)")
            }
            
            
            
            if let xxx = getAppNameWithId(currentProfile.sessions[dayOfWeekString]?.amSession.apps.first) {
                
                Text(xxx)
            }
            if let zzz = currentProfile.sessions[dayOfWeekString]?.amSession.apps.first {
                
                Text("\(zzz)")
            }
            
 */
            
            VStack(alignment: .leading, spacing: 12) {
/* 
                Text("Monday")
                    .font(.title)
                    .padding([.top, .leading])
                    .padding(.bottom,4)
                
                Divider().foregroundColor(.red)
                
 */
                
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

                    //                SessionGroupView(timeOfDay: "**Home:** - 9:00 - 11:59",
                    //                                 sessionLength: 20,
                    //                                 iPadLockedIntoApp: true,
                    //                                 seesionNumber: 3)
                .padding(.bottom)
                
                    //                Rectangle().fill(.secondary).opacity(0.2).frame(maxWidth: .infinity, minHeight: 1, idealHeight: 3, maxHeight: 6)
            }
            .frame(width: 340)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding()
            
        }
    }
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
        
        .onChange(of: appxViewModel.isLoaded) { isDataLoaded in
            if isDataLoaded {
                processApps()
            }
        }
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


//struct OneCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        ShowStudentProfiileDayView()
//    }
//}

struct SessionGroupView: View {
    @EnvironmentObject  var appxViewModel:  AppxViewModel
    @State private var isEditing = false
    @State   var selectedNum: Double = 0.0
    
    let timeOfDay:                      LocalizedStringKey
    @Binding var sessionLength:         Int {
        didSet {
            selectedNum = Double(sessionLength)
        }
    }

    @Binding var iPadLockedIntoApp:     Bool
    let seesionNumber:                  Int
    @Binding var appList:               String
    @Binding var isSheetPresented:      Bool
    @Binding var appCodeAM:             Int
    @Binding var sessionLengthDoubleAM: Double
    
    var body: some View {
        Group {
            HStack {
                Text(timeOfDay)
                    .padding([ .leading])
                Spacer()
                Button("Set Student App ") {
                    isSheetPresented.toggle()
                }.padding(.trailing)
            }
            VStack(alignment: .leading, spacing: 4) {
//                Text("**appCode:** \(appCodeAM) ")
                HStack {
                    Text("Minutes: \(sessionLengthDoubleAM, specifier: "%.f")   ")
                        .font(.headline)
                        .bold()
                    Slider(value: $sessionLengthDoubleAM, in: 5...60, step: 5.0){
                        Text("Slider")
                    } minimumValueLabel: {
                        Text("5")
                    } maximumValueLabel: {
                        Text("60")
                    } onEditingChanged: { editing in
                        isEditing = editing
                    }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                Toggle(isOn: $iPadLockedIntoApp, label: {
                    Text("Locked INto the App").font(.headline)
                }).disabled(true)
                
                Text("**Session Length:** \(sessionLength) minutes")
                Text("**iPad Locked to app:** \( iPadLockedIntoApp ? "Locked" : "Not Locked")")
                Divider()
                VStack {
                    Label {
                        if let appName = getAppNameWithId(appCodeAM) {
                            Text("\(appName)")
                        } else {
                            Text("eiodjijf3pihf3ifh3ofhi3ofihi3foih")
                        }
                    } icon: {
                        if let app = getAppWithId(appCodeAM) {
                            AsyncImage(url: URL(string: app.icon)) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 48, height: 48)

//                            Image("Dkdkdk")
//                                .resizable()
//                                .frame(width: 48, height: 48, alignment: .leading)
                        }
                    }
                    Text(" this is just a small description of the app and it should go from one side to the other").foregroundColor(.gray).font(.footnote)
                }
                .padding([.top])
            }
            .padding()
            .background(Color.orange.opacity(0.2))
            .cornerRadius(10)
            .padding([.horizontal])
        }
        .onAppear {
           
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
    

}
