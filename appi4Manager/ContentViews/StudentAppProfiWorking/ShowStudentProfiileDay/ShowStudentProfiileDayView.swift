//
//  ShowStudentProfiileDayView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/16/23.
//

import SwiftUI


struct ShowStudentProfiileDayView: View {
    
    //  MARK: -  Properties
    @ObservedObject     var studentAppProfileViewModel =    StudentAppProfileViewModel()
    @EnvironmentObject  var appxViewModel:                  AppxViewModel
    @State              var currentProfile:                 StudentAppProfile
    @State private      var dayProfile:                     DailySessions? = nil
    
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
    Array(repeating: DailySessionConfiguration(oneAppLockAM: false, appCodeAM: 0,sessionLengthAM: 0 ), count: 7)
//    @State var singleAppMode
    
    var studentAppProfilesList: [StudentAppProfile]

//	properties to communicate with disclosure app and group box
    
    
    @State var oneAppLockAM: Bool = false
    @State var oneAppLockPM: Bool = false
    
    @State var appListAM = ""
    @State var appListPM = ""
    
    @State var appCodeAM = 0
    @State var appCodePM = 0

    @State var sessionLengthAM = 0
    @State var sessionLengthPM = 0

    
    @State private var isSheetPresented = false
    @State private var selectedSession: Session?
    
    fileprivate func updateTheStudent(_ theapp: Int, _ returnedSession: Session) {
        
        print(theapp)
        print(returnedSession.oneAppLock)
        print(returnedSession.sessionLength)
        currentProfile.sessions["Sunday"]?.amSession = returnedSession
        
        if  let theapp = currentProfile.sessions["Sunday"]?.amSession.apps.first {
            print(theapp)
        }
        
        print(currentProfile.sessions["Sunday"]?.amSession.oneAppLock)
        print(currentProfile.sessions["Sunday"]?.amSession.sessionLength)
        
        
        studentAppProfileViewModel.profiles = studentAppProfilesList
        
        if let idx = studentAppProfileViewModel.profiles.firstIndex(where: { prf in
            prf.id == 8
        }) {
                // 5
            studentAppProfileViewModel.profiles[idx] = currentProfile
                //6
            studentAppProfileViewModel.saveProfiles()
            
        } else {
            print("no match")
        }
    }
    
    var body: some View {
        
        VStack {
            Text("Sam Ashe - App Profile").padding([.top, .bottom], 16)
          

            Text("lock to one app \(oneAppLockAM ? "yes" : "No")")
            
            if let sessionLength = currentProfile.sessions["Sunday"]?.amSession.sessionLength {
                Text("length: \(sessionLength)")
            }
            
            
            
            if let xxx = getAppNameWithId(currentProfile.sessions["Sunday"]?.amSession.apps.first) {
                
                Text(xxx)
            }
            if let zzz = currentProfile.sessions["Sunday"]?.amSession.apps.first {
                
                Text("\(zzz)")
            }


            VStack(alignment: .leading, spacing: 12) {
                Text("Monday")
                    .font(.title)
                    .padding([.top, .leading])
                    .padding(.bottom,4)
                
                Divider().foregroundColor(.red)
                
                SessionGroupView(timeOfDay:         "**AM:** - 9:00 - 11:59",
                                 sessionLength:     $dailySessionConfigurationx[0].sessionLengthAM,
//                                 sessionLength:     $sessionLengthAM,
                                 iPadLockedIntoApp: $oneAppLockAM,
                                 seesionNumber:     1,
                                 appList:           $appListAM,
                                 isSheetPresented:  $isSheetPresented,
                                 appCodeAM:         $appCodeAM)
                SessionGroupView(timeOfDay:         "**PM:** - 9:00 - 11:59",
                                 sessionLength:     $sessionLengthPM,
                                 iPadLockedIntoApp: $oneAppLockPM,
                                 seesionNumber:     2,
                                 appList:           $appListPM,
                                 isSheetPresented:  $isSheetPresented,
                                 appCodeAM:         $appCodePM)
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
            guard let xoneAppLockAM = currentProfile.sessions["Sunday"]?.amSession.oneAppLock else { fatalError("one app lock failed") }
            oneAppLockAM = xoneAppLockAM
            
            
            
            
            // load it to regular data
            if let returnedSession = selectedSession,
               let theapp = returnedSession.apps.first {
                print("##-##", theapp)
                selectedSession = nil
            } else {
                print("returned is nill")
            }
            
            guard let theAMSession = currentProfile.sessions["Sunday"]?.amSession else {fatalError("dd")}
            
            var xx = DailySessionConfiguration(oneAppLockAM: true, appCodeAM: 99, sessionLengthAM: 111)
            dailySessionConfigurationx[0].sessionLengthAM = theAMSession.sessionLength
//            studentAppProfileViewModel.dailySessionConfiguration[0].sessionLengthAM = 111
//            sessionLengthAM = theAMSession.sessionLength
            oneAppLockAM    = theAMSession.oneAppLock
            
            if let theOneApp = currentProfile.sessions["Sunday"]?.amSession.apps.first {
                appCodeAM = theOneApp
            }
            

        }
        
        .onChange(of: appxViewModel.isLoaded) { isDataLoaded in
            if isDataLoaded {
                processApps()
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            CategoryDisclosureView(selectedSession: $selectedSession,
                                   isSheetPresented: $isSheetPresented,
                                   lengthOfSesssion: $dailySessionConfigurationx[0].sessionLengthAM, singleAppMode: $oneAppLockAM, appCodeAM: $appCodeAM)
//                                   lengthOfSesssion: $sessionLengthAM, singleAppMode: $oneAppLockAM, appCodeAM: $appCodeAM)
                .onDisappear {
                    if let returnedSession = selectedSession,
                       let theapp = returnedSession.apps.first {
                        updateTheStudent(theapp, returnedSession)
                       
                    } // end if
         
                } // end onDisappear
        } // end sheet

    }
}

extension ShowStudentProfiileDayView {
    func processApps() {

        guard let amApps = currentProfile.sessions["Sunday"]?.amSession.apps else { fatalError("Big Error") }
        print("----",amApps)
        for appCode in amApps {
            if let appName = getAppWithId(appCode)?.name {
                appCodexAM = appCode
                appListStringAM.append(appName)
            }
        }

        print(currentProfile.sessions["Sunday"]?.pmSession.apps)
        guard let pmApps = currentProfile.sessions["Sunday"]?.pmSession.apps else { fatalError("Big Error") }
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
    
    let timeOfDay:                      LocalizedStringKey
    @Binding var sessionLength:         Int
    @Binding var iPadLockedIntoApp:     Bool
    let seesionNumber:                  Int
    @Binding var appList:               String
    @Binding var isSheetPresented:      Bool
    @Binding var appCodeAM:             Int
    
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
                Text("**appCode:** \(appCodeAM) ")
                
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
