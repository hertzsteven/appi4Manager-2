//
//  AppProfileWeeklyView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/9/23.
//

import SwiftUI

struct AppProfileWeeklyView: View {
    
    //  MARK: -  Properties
    @ObservedObject     var viewModel =     StudentAppProfileViewModel()
    @EnvironmentObject  var appxViewModel:  AppxViewModel
    @State              var currentProfile: StudentAppProfile
    @State private      var dayProfile:     DailySessions? = nil
    
    // to control the Load
    @State private var hasError = false
    @State private var error: ApiError?
    @State private var showApps: Bool = false
    
    // Temp To test stuff
    @State var appListString: Array<String> = []
    @State var appCodex: Int = 0
    
    //  MARK: -  Body
    var body: some View {
        
        VStack {
            Text("sksks \(currentProfile.id)  \(appxViewModel.appx.count) and \(appCodex)")
                .padding([.top, .bottom], 16)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Monday")
                    .font(.title)
                    //                .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .topLeading)
                    .padding([.top, .leading])
                    .padding(.bottom,4)
                Divider().foregroundColor(.red)
                Group {
                    Text("**AM:** - 9:00 - 11:59")
                        .padding([ .leading])
                        //                    Text("App Profile")
                        //                        .padding(.leading, 16.0)
                        //                        //                    .padding(.top, 1.0)
                    VStack(alignment: .leading, spacing: 4) {
                            //                        Text("App Profile")
                            //                            .font(.headline)
                            //                        Divider()
                            //                            .padding()
                        Text("**Session Length:** 20 minutes")
                        Text("**Configration:** Locked into one App")
                        Divider()
                        VStack {
                            Label {
                                Text("Elmo Loves the ABCs and what happens if more")
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
                                Text("Elmo Loves the ABCs and what happens if more")
                            } icon: {
                                Image("tabby")
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
        print(amApps)
        for appCode in amApps {
            if let appName = getAppWithId(appCode)?.name {
                appCodex = appCode
                appListString.append(appName)
            }
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

struct AppProfileWeeklyView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample StudentAppProfile
        let sampleProfile = StudentAppProfile(
            id: 1,
            locationId: 1,
            sessions: ["Monday": DailySessions(
                amSession: Session(apps: [27], sessionLength: 20, oneAppLock: true),
                pmSession: Session(apps: [34], sessionLength: 20, oneAppLock: true),
                homeSession: Session(apps: [27], sessionLength: 20, oneAppLock: true)
            )]
        )
        
        // Sample AppxViewModel
        let appxViewModel = AppxViewModel()
        
        return AppProfileWeeklyView(currentProfile: sampleProfile)
            .environmentObject(appxViewModel)
    }
}

