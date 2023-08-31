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
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}


struct MockToStudentScreenView: View {
    
        //  MARK: -  Properties
    
    
    var studentAppProfilefiles: [StudentAppProfile] = []
    
    @State private var selectedDay = DayOfWeek.sunday
    
    @State var studentId: Int
    
    
    @State var studentAppprofile: StudentAppProfile
    
    @State var currentDayStudentAppProfile: DailySessions = DailySessions.makeDefaultDailySession()
    
    @State var currentDayStudentAppProfileSave: DailySessions = DailySessions.makeDefaultDailySession()
    
    
    
        //  MARK: -  Control the popup
    @State var presentMakeAppProfile: Bool = false
    
    @State var timeOfDay = TimeOfDay.am
    
    
        //  MARK: -  body
    
    var body: some View {
        
        VStack(spacing: 16) {
            
            Picker("Select a day of the week", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id:\.self) { day in
                    Text(day.asAString).tag(day.rawValue)
                }
            }.pickerStyle(.segmented)
                .padding(.top, 32)
            
            Divider().padding()
            HStack {
                Button("Update Sunday") {
                    currentDayStudentAppProfile.amSession.sessionLength = 44
                    studentAppprofile.sessions["Sunday"]!.amSession.sessionLength = 44
                    dump(studentAppprofile)
                }
                
                Button("Update Monday") {
                    currentDayStudentAppProfile.amSession.sessionLength = 44
                    studentAppprofile.sessions["Monday"]!.amSession.sessionLength = 44
                    dump(studentAppprofile)
                }
                
                Button("GoToAPPProfileSetupAM") {
                    timeOfDay = .am
                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
                    presentMakeAppProfile.toggle()
                }
                
                Button("GoToAPPProfileSetupPM") {
                    timeOfDay = .pm
                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
                    presentMakeAppProfile.toggle()
                }
            }
            
            amGroupBox()
            
            GroupBox {
                Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
                Text("Length of seconds \(currentDayStudentAppProfile.amSession.sessionLength)").padding()
            }label: {
                Text("am session")
            }
            GroupBox {
                Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
                Text("Length of seconds \(currentDayStudentAppProfile.pmSession.sessionLength)").padding()
            } label: {
                Text("pm session")
            }
            
            Spacer()
            
        }
        
        .sheet(isPresented: $presentMakeAppProfile, onDismiss: {
            print("dismissed makeAppProfile")
            if currentDayStudentAppProfile != currentDayStudentAppProfileSave {
                print(" they are not equal")
                upDateStudentAppProfile()
            } else {
                print("they are equal")
            }
        }, content: {
            MockSetupAppProfileView(presentMakeAppProfile: $presentMakeAppProfile,
                                    selectedDay: selectedDay,
                                    sessionLength: {
                switch timeOfDay {
                case .am:
                    return $currentDayStudentAppProfile.amSession.sessionLength
                case .pm:
                    return $currentDayStudentAppProfile.pmSession.sessionLength
                case .home:
                    return $currentDayStudentAppProfile.homeSession.sessionLength
                }
            }())
        })
        
        
        .onAppear {
            setCurrentDateWith(selectedDay.asAString)
        }
        
        .onChange(of: selectedDay) { newValue in
            setCurrentDateWith(newValue.asAString)
        }
        
    }
        //  MARK: -  Funcs for Views
    func amGroupBox(theTitle: String = "am session")-> some View {
        return  GroupBox {
            Text("Student Code \(studentId) and \(studentAppprofile.sessions.count)").padding()
            Text("Length of seconds \(currentDayStudentAppProfile.amSession.sessionLength)").padding()
        }label: {
            Text(theTitle)
        }
    }
    
        //  MARK: -  Funcs to assist in processes
    func setCurrentDateWith(_ stringDayOfWeek: String)  {
        guard let currentDayStudentAppProfilefilxe = studentAppprofile.sessions[stringDayOfWeek] else {
            fatalError("big error")
        }
        currentDayStudentAppProfile = currentDayStudentAppProfilefilxe
    }
    
    func upDateStudentAppProfile()  {
        switch timeOfDay {
        case .am:
            dump(studentAppprofile)
            studentAppprofile.sessions[selectedDay.asAString]?.amSession.sessionLength = currentDayStudentAppProfile.amSession.sessionLength
            dump(studentAppprofile)
        case .pm:
            studentAppprofile.sessions[selectedDay.asAString]?.pmSession.sessionLength = currentDayStudentAppProfile.pmSession.sessionLength
        case .home:
            studentAppprofile.sessions[selectedDay.asAString]?.homeSession.sessionLength = currentDayStudentAppProfile.homeSession.sessionLength
        }
//        if let idx = studentAppProfilefiles.firstIndex(where: {  $0.id == studentId  }) {
//            studentAppProfilefiles[idx] = profile
//            dump(studentAppProfilefiles)
//        }
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
