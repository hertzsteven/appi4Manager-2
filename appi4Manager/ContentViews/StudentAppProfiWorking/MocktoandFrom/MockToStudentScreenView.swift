//
//  MockToStudentScreenView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/28/23.


import SwiftUI

enum TimeOfDay {
    case am
    case pm
    case home
}

enum DayOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var asAString: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tues"
        case .wednesday: return "Wed"
        case .thursday: return "Thurs"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

class StudentAppProfilex: Identifiable, Codable, ObservableObject {
                var id              : Int
                var locationId      : Int
    @Published  var sessions        : [String: DailySessions]
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationId
        case sessions
    }

    required init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        id             = try container.decode(Int.self, forKey: .id)
        locationId     = try container.decode(Int.self, forKey: .locationId)
        sessions       = try container.decode([String: DailySessions].self, forKey: .sessions)
    }

    // Implementing the Encodable protocol manually
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(sessions, forKey: .sessions)
    }

    init(id: Int, locationId: Int, sessions: [String: DailySessions]) {
        self.id          = id
        self.locationId  = locationId
        self.sessions    = sessions
    }
}

class StudentAppProfileManager: ObservableObject {
    @Published var studentAppProfileFiles: [StudentAppProfilex] = []
    
    static func loadProfilesx() -> [StudentAppProfilex] {
        if let savedProfiles = UserDefaults.standard.object(forKey: "StudentProfiles6") as? Data {
            if let decoded = try? JSONDecoder().decode([StudentAppProfilex].self, from: savedProfiles) {
                if decoded.count == 0 {
                    let sampleprofiles = StudentAppProfileManager.sampleProfile()
                    StudentAppProfileManager.savePassedProfiles(profilesToSave: sampleprofiles)
                    return sampleprofiles
                } else {
                    return decoded
                }
            }
        }
        let sampleprofiles = StudentAppProfileManager.sampleProfile()
        StudentAppProfileManager.savePassedProfiles(profilesToSave: sampleprofiles)
        return sampleprofiles
    }
    
    func updateStudentAppProfile(newProfile: StudentAppProfilex) {
        if let idx = studentAppProfileFiles.firstIndex(where: { $0.id == newProfile.id }) {
            studentAppProfileFiles.remove(at: idx)
            studentAppProfileFiles.append(newProfile)
        }
    }
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(studentAppProfileFiles) {
            if let idx = studentAppProfileFiles.firstIndex(where: { prf in
                prf.id == 8
            }) {
                    // 5
                dump(studentAppProfileFiles[idx])
            }
            UserDefaults.standard.set(encoded, forKey: "StudentProfiles6")
        }
    }
    
    static func savePassedProfiles(profilesToSave: [StudentAppProfilex]) {
        if let encoded = try? JSONEncoder().encode(profilesToSave) {
            UserDefaults.standard.set(encoded, forKey: "StudentProfiles6")
        }
    }
}

// generating Mockes
extension StudentAppProfileManager {
    
    static func makeDefaultfor(_ id: Int, locationId: Int) -> StudentAppProfilex {
         generateSampleProfileforId(id: id, locationId: locationId, apps: [], sessionLength: 0, oneAppLock: false)
    }

    static func sampleProfile() -> [StudentAppProfilex] {
        
        let sampleProfile1 = generateSampleProfileforId(id: 3, locationId: 0, apps: [11,34], sessionLength: 20, oneAppLock: false)
        let sampleProfile2 = generateSampleProfileforId(id: 8, locationId: 0, apps: [27], sessionLength: 30, oneAppLock: false)
        let sampleProfile3 = generateSampleProfileforId(id: 48, locationId: 0, apps: [34], sessionLength: 15, oneAppLock: true)
        
        return [sampleProfile1, sampleProfile2, sampleProfile3 ]
    }
    
    static func generateSampleProfileforId(id: Int, locationId: Int, apps:[Int], sessionLength: Double, oneAppLock: Bool ) ->  StudentAppProfilex {
        let sampleSession = Session(apps: apps, sessionLength: sessionLength, oneAppLock: oneAppLock)
        let sampleDailySessions = DailySessions(amSession: sampleSession, pmSession: sampleSession, homeSession: sampleSession)
        
        let sampleProfile = StudentAppProfilex(
            id: id,
            locationId: locationId,
            sessions: [
                "Sun":       sampleDailySessions,
                "Mon":       sampleDailySessions,
                "Tues":      sampleDailySessions,
                "Wed":    sampleDailySessions,
                "Thurs":     sampleDailySessions,
                "Fri":       sampleDailySessions,
                "Sat":     sampleDailySessions
            ]
        )
        return sampleProfile
    }
    
}



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
    
    @State var appCode = 0
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

//  MARK: -  For views
extension MockToStudentScreenView {
    
    func amGroupBox(theTitle: String = "am session")-> some View {
        return  GroupBox {
            Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
            let stringArray     = currentDayStudentAppProfile.amSession.apps.map { String($0) }
            let joinedString    = stringArray.joined(separator: ",")
                Text("App codes: \(joinedString)")
             if let theApps = currentDayStudentAppProfile.amSession.apps.first {
                Text("App codes: \(theApps)")
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
