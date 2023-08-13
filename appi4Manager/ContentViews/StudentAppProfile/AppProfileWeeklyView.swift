//
//  AppProfileWeeklyView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/9/23.
//

import SwiftUI

struct AppProfileWeeklyView: View {
    
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
    
    var studentAppProfilesList: [StudentAppProfile]

    
    //  MARK: -  Body
    var body: some View {
        
        VStack {
            Text("sksks \(currentProfile.id)  \(appxViewModel.appx.count) and \(appListStringAM.joined())")
                .padding([.top, .bottom], 16)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Monday")
                    .font(.title)
                     .padding([.top, .leading])
                    .padding(.bottom,4)
                Divider().foregroundColor(.red)
                Group {
                    Text("**AM:** - 9:00 - 11:59")
                        .padding([ .leading])
                    VStack(alignment: .leading, spacing: 4) {
                        Text("**Session Length:** 20 minutes")
                        Text("**Configration:** Locked into one App")
                        Divider()
                        VStack {
                            Label {
                                Text("\(appListStringAM.joined())")
                            } icon: {
                                Image("heartshare")
                                    .resizable()
                                    .frame(width: 48, height: 48, alignment: .leading)
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
                Rectangle().fill(.secondary).opacity(0.2).frame(maxWidth: .infinity, minHeight: 2, maxHeight: 6)
                Group {
                    Text("**PM:** - 12:00 - 4:59")
                        .padding([ .leading])
                    Text("App Profile")
                        .padding(.leading, 16.0)
                        //                    .padding(.top, 1.0)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Profile")
                            .font(.headline)
                        Divider()
                            .padding()
                        Text("**Session Length:** 20 minutes")
                        Text("**Configration:** Locked into one App")
                        Divider()
                        VStack {
                            Label {
                                Text("\(appListStringPM.joined())")
                            } icon: {
                                Image("heartshare")
                                    .resizable()
                                    .frame(width: 48, height: 48, alignment: .leading)
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
                
                Spacer()
            }
            .frame(width: 340)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding()
        }
        
        //  MARK: -  Modifiers for data flow

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
        }
        
        .onChange(of: appxViewModel.isLoaded) { isDataLoaded in
            if isDataLoaded {
                processApps()
            }
        }
    }
}

extension AppProfileWeeklyView {
    //  MARK: -  Functions

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
    
    func updateProfileWithdailySessions(_ dailySessions: DailySessions) {
    
        guard var sundaySessions = currentProfile.sessions["Sunday"] else {
            print("Sunday sessions not found")
            return
        }
        
        sundaySessions.amSession.apps = dailySessions.amSession.apps
        sundaySessions.amSession.sessionLength = dailySessions.amSession.sessionLength
        print(sundaySessions.pmSession.apps)

        sundaySessions.pmSession.apps = dailySessions.pmSession.apps
        print(sundaySessions.pmSession.apps)

        sundaySessions.homeSession.apps = dailySessions.homeSession.apps
        print(sundaySessions.pmSession.apps)

        currentProfile.sessions["Sunday"] = sundaySessions
        dump(currentProfile.sessions["Sunday"])
        

        studentAppProfileViewModel.profiles = studentAppProfilesList

        if let idx = studentAppProfileViewModel.profiles.firstIndex(where: { prf in
            prf.id == 8
        }) {
            studentAppProfileViewModel.profiles[idx] = currentProfile
            studentAppProfileViewModel.saveProfiles()

        } else {
            print("no match")
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

//struct AppProfileWeeklyView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Sample StudentAppProfile
//        let sampleProfile = StudentAppProfile(
//            id: 1,
//            locationId: 1,
//            sessions: ["Monday": DailySessions(
//                amSession: Session(apps: [27], sessionLength: 20, oneAppLock: true),
//                pmSession: Session(apps: [34], sessionLength: 20, oneAppLock: true),
//                homeSession: Session(apps: [27], sessionLength: 20, oneAppLock: true)
//            )]
//        )
//
//        // Sample AppxViewModel
//        let appxViewModel = AppxViewModel()
//
//        return AppProfileWeeklyView(currentProfile: sampleProfile)
//            .environmentObject(appxViewModel)
//    }
//}
//
