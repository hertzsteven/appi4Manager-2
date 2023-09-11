//
//  StudentAppProfileWorkingView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 9/10/23.
//

import SwiftUI


struct StudentAppProfileWorkingView {
    @State var sessionLengthDoubleAM: Double = 25
    @State var sessionLengthDoublePM: Double = 10
    
        //  MARK:  Properties
    @State private var selectedDay = DayOfWeek.sunday
    
    @State var studentId: Int
    
    //  MARK: Manage Student Profile
    var studentAppProfilefiles: [StudentAppProfilex]        = []
    @StateObject var profileManager                         : StudentAppProfileManager
    @StateObject var studentAppprofile                      : StudentAppProfilex
    @State var currentDayStudentAppProfile: DailySessions   = DailySessions.makeDefaultDailySession()

    //  MARK: Properties to help with processes
    @State var currentDayStudentAppProfileSave: DailySessions = DailySessions.makeDefaultDailySession()
    
    
    //  MARK:  Control the popup
    @State var presentMakeAppProfile: Bool  = false
    @State var timeOfDay                    = TimeOfDay.am
    
    @State var appCode = 0
    @State private var selectedSession: Session?

    
    @State private var isEditing: Bool = false
    
}

extension StudentAppProfileWorkingView: View {
    
    var headerView: some View {
        Group {
            Picker("Select a day of the week", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id:\.self) { day in
                    Text(day.asAString).tag(day.rawValue)
                }
            }.pickerStyle(.segmented)
                .padding([.top, .horizontal] )
        }
    }

    var amGroupView: some View {
        
        GroupBox {
            
            VStack(alignment: .leading) {
                
                HStack {
                    Text("Minutes: \(55, specifier: "%.f")   ")
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
                    }.disabled(true)
                }
                
                if let theApps = currentDayStudentAppProfile.amSession.apps.first {
                    Text("App codes: \(theApps)")
                }
                
                Text("Length of seconds \(currentDayStudentAppProfile.amSession.sessionLength)").padding()
                
                Text("App lock is \(currentDayStudentAppProfile.amSession.oneAppLock ? "true" : "false")")

                
            }
        }label: {
            HStack {
                
                Text("**AM:** 9:00- 11:59 ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                                            timeOfDay = .am
                                            currentDayStudentAppProfileSave = currentDayStudentAppProfile
                                            presentMakeAppProfile.toggle()
                } label: {
                    Text("Set It 🔆")
                }
                
            }.padding(.bottom)
        }
        .padding()
    }
    
    
    var mainView: some View {
        Group {
            amGroupView
            
//            SessionGroupVw(sessionLengthDoubleAM: sessionLengthDoubleAM)
//            SessionGroupVw(sessionLengthDoubleAM: sessionLengthDoublePM)
//            SessionGroupVw(sessionLengthDoubleAM: sessionLengthDoublePM)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                headerView
                mainView
            }
            .frame(width: 380)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
        .padding()
        }
        .sheet(isPresented: $presentMakeAppProfile, onDismiss: {
            print("dismissed makeAppProfile")
            if currentDayStudentAppProfile != currentDayStudentAppProfileSave {
                print(" they are not equal")
                upDateStudentAppProfile()
                profileManager.updateStudentAppProfile(newProfile: studentAppprofile)
                profileManager.saveProfiles()
            } else {
                print("they are equal")
            }
        })
//        {MockSetupAppProfileView(presentMakeAppProfile   : $presentMakeAppProfile,
//                                    selectedDay             : selectedDay,
//                                    sessionLength           : getSessionLengthBinding(),
//                                    apps                    : getappsBinding(),
//                                    oneAppLock              : getoneAppLockBinding()
//        )
//        }
//
        {
                   CategoryDisclosureView(selectedSession  : $selectedSession,
                                          isSheetPresented : $presentMakeAppProfile,
                                          sessionLength    : getSessionLengthBinding(),
                                          oneAppLock       : getoneAppLockBinding(),
                                          appCode          : $appCode,
                                          apps             : getappsBinding() )
               }
        
        .onAppear {
            profileManager.studentAppProfileFiles = studentAppProfilefiles
            setCurrentDateWith(selectedDay.asAString)
        }
        
        
        .onChange(of: selectedDay) { newValue in
            setCurrentDateWith(newValue.asAString)
        }

 
    }
    
}

extension StudentAppProfileWorkingView {
    
    func getSessionLengthBinding() -> Binding<Int> {
        switch timeOfDay {
        case .am:
            return $currentDayStudentAppProfile.amSession.sessionLength
        case .pm:
            return $currentDayStudentAppProfile.pmSession.sessionLength
        case .home:
            return $currentDayStudentAppProfile.homeSession.sessionLength
        }
    }
    
    func getappsBinding() -> Binding<[Int]> {
        switch timeOfDay {
        case .am:
            return $currentDayStudentAppProfile.amSession.apps
        case .pm:
            return $currentDayStudentAppProfile.pmSession.apps
        case .home:
            return $currentDayStudentAppProfile.homeSession.apps
        }
    }
    
    func getoneAppLockBinding() -> Binding<Bool> {
        switch timeOfDay {
        case .am:
            return $currentDayStudentAppProfile.amSession.oneAppLock
        case .pm:
            return $currentDayStudentAppProfile.pmSession.oneAppLock
        case .home:
            return $currentDayStudentAppProfile.homeSession.oneAppLock
        }
    }
    
}


extension StudentAppProfileWorkingView {
    
    func setCurrentDateWith(_ stringDayOfWeek: String)  {
        guard let currentDayStudentAppProfilefilxe = studentAppprofile.sessions[stringDayOfWeek] else {
            fatalError("big error")
        }
        currentDayStudentAppProfile = currentDayStudentAppProfilefilxe
    }
    
    //  MARK: -  Update the student profile
    func upDateStudentAppProfile()  {
        switch timeOfDay {
        case .am:
            studentAppprofile.sessions[selectedDay.asAString]?.amSession.sessionLength = currentDayStudentAppProfile.amSession.sessionLength
            studentAppprofile.sessions[selectedDay.asAString]?.amSession.apps = currentDayStudentAppProfile.amSession.apps
            studentAppprofile.sessions[selectedDay.asAString]?.amSession.oneAppLock = currentDayStudentAppProfile.amSession.oneAppLock
        case .pm:
            studentAppprofile.sessions[selectedDay.asAString]?.pmSession.sessionLength = currentDayStudentAppProfile.pmSession.sessionLength
            studentAppprofile.sessions[selectedDay.asAString]?.pmSession.apps = currentDayStudentAppProfile.pmSession.apps
            studentAppprofile.sessions[selectedDay.asAString]?.pmSession.oneAppLock = currentDayStudentAppProfile.pmSession.oneAppLock
        case .home:
            studentAppprofile.sessions[selectedDay.asAString]?.homeSession.sessionLength = currentDayStudentAppProfile.homeSession.sessionLength
            studentAppprofile.sessions[selectedDay.asAString]?.homeSession.apps = currentDayStudentAppProfile.homeSession.apps
            studentAppprofile.sessions[selectedDay.asAString]?.homeSession.oneAppLock = currentDayStudentAppProfile.homeSession.oneAppLock
        }
    }
    
}

struct SessionGroupVw {
    @State private  var isEditing                :Bool = false
    @State          var sessionLengthDoubleAM    :Double
    @State          var iPadLockedIntoApp        :Bool = true
    
    @State var timeOfDay                                = TimeOfDay.am

}


extension SessionGroupVw: View {
    
    var sessionLengthView:  some View {
        HStack {
            Text("Minutes: \(55, specifier: "%.f")   ")
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
    }
    
    var oneAppLockView:     some View {
        Toggle(isOn: $iPadLockedIntoApp, label: {
            Text("Locked into the App:").font(.headline)
        }).disabled(true)
    }
    
    var appSelectedView:    some View {
        
        HStack {
            
            Image("iconImage")
                .resizable()
                .frame(width: 64, height: 64, alignment: .center)
                .padding([.top, .trailing])
            
            VStack(alignment: .leading) {
                Text("Elmo Loves ABC")
                    .bold()
                Text("this is just a small description of the app and it should go from one side to the other")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            
        }
        
    }
    
    
    var body: some View {
        
        GroupBox {
            
            VStack(alignment: .leading) {
                
                sessionLengthView
                
                oneAppLockView
                
                appSelectedView
                
            }
        } label: {
            HStack {
                
                Text("**AM:** 9:00- 11:59 ")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
//                    timeOfDay = .am
//                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
//                    presentMakeAppProfile.toggle()
                } label: {
                    Text("Set It 🔆")
                }

            }.padding(.bottom)
        }
        .padding()
        
    }
    
}

//struct StudentAppProfileWorkingView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentAppProfileWorkingView()
//    }
//}
