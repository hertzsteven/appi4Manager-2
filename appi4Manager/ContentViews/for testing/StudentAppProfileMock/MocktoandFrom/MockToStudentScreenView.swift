//
//  MockToStudentScreenView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/28/23.


import SwiftUI





//  MARK:   After Classes before View

struct MockToStudentScreenView: View {
    
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
    
    @State var appCode = ""
    @State private var selectedSession: Session?
    
}


//  MARK: -  body
extension MockToStudentScreenView {
    
    var controlView: some View {
            // Control day displayed and update Infor
        Group {
            Picker("Select a day of the week", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id:\.self) { day in
                    Text(day.asAString).tag(day.rawValue)
                }
            }.pickerStyle(.segmented)
                .padding(.top, 32)
            
            Divider().padding()
            
            HStack {
                Button("GoToAPPProfile SetupAM") {
                    timeOfDay = .am
                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
                    presentMakeAppProfile.toggle()
                }
                
                Button("GoToAPPProfile SetupPM") {
                    timeOfDay = .pm
                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
                    presentMakeAppProfile.toggle()
                }
            }
        }

    }
    
    var displayInfoView: some View {
        Group {
            
            amGroupBox()
            
            GroupBox {
                Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
                
                if let theApps = currentDayStudentAppProfile.pmSession.apps.first {
                    Text("App codes: \(theApps)")
                }
                
                Text("Length of seconds \(currentDayStudentAppProfile.pmSession.sessionLength)").padding()
                
                Text("App lock is \(currentDayStudentAppProfile.pmSession.oneAppLock ? "true" : "false")")
            } label: {
                Text("pm session")
            }
        }
    }
    
    var body: some View {
        
        VStack(spacing: 16) {

            controlView
            
            displayInfoView

            Spacer()
            
        }
        
        .sheet(isPresented: $presentMakeAppProfile, onDismiss: {
            print("dismissed makeAppProfile")
            if currentDayStudentAppProfile != currentDayStudentAppProfileSave {
                print(" they are not equal")
                upDateStudentAppProfile()
                profileManager.updateStudentAppProfile(newProfile: studentAppprofile)
//                profileManager.saveProfiles()
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

//  MARK: -  For views
extension MockToStudentScreenView {
    
    func amGroupBox(theTitle: String = "am session")-> some View {
        return  GroupBox {
            Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
            let joinedString = currentDayStudentAppProfile.amSession.apps.joined(separator: ", ")
            Text("App bundle IDs: \(joinedString)")
            if let theApps = currentDayStudentAppProfile.amSession.apps.first {
                Text("First app bundle ID: \(theApps)")
            }
            Text("Length of seconds \(currentDayStudentAppProfile.amSession.sessionLength)").padding()
            Text("App lock is \(currentDayStudentAppProfile.amSession.oneAppLock ? "true" : "false")")
            
        }label: {
            Text(theTitle)
        }
    }
}

//  MARK: -  For communication with other Struct
extension MockToStudentScreenView {
    
    func getSessionLengthBinding() -> Binding<Double> {
        switch timeOfDay {
        case .am:
            return $currentDayStudentAppProfile.amSession.sessionLength
        case .pm:
            return $currentDayStudentAppProfile.pmSession.sessionLength
        case .home:
            return $currentDayStudentAppProfile.homeSession.sessionLength
        }
    }
    
    func getappsBinding() -> Binding<[String]> {
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

//  MARK: -  Funcs for work
extension MockToStudentScreenView {
    
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







//struct MockToStudentScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        MockToStudentScreenView(studentId: 8)
//    }
//}




    //    var sundayProfile:      DailySessions = DailySessions.makeDefaultDailySession()
    //    var mondayProfile:      DailySessions = DailySessions.makeDefaultDailySession()
    //    var tuesdayProfile:     DailySessions = DailySessions.makeDefaultDailySession()
    //    var wednesdayProfile:   DailySessions = DailySessions.makeDefaultDailySession()
    //    var thursdayProfile:    DailySessions = DailySessions.makeDefaultDailySession()
    //    var fridayProfile:      DailySessions = DailySessions.makeDefaultDailySession()
    //    var saturdayProfile:    DailySessions = DailySessions.makeDefaultDailySession()



//                                    sessionLength           : {
//                switch timeOfDay {
//                case .am:
//                    return $currentDayStudentAppProfile.amSession.sessionLength
//                case .pm:
//                    return $currentDayStudentAppProfile.pmSession.sessionLength
//                case .home:
//                    return $currentDayStudentAppProfile.homeSession.sessionLength
//                }
//            }(),
//                                    apps                    : {
//                switch timeOfDay {
//                case .am:
//                    return $currentDayStudentAppProfile.amSession.apps
//                case .pm:
//                    return $currentDayStudentAppProfile.pmSession.apps
//                case .home:
//                    return $currentDayStudentAppProfile.homeSession.apps
//                }
//            }()
