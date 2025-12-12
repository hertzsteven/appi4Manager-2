
//
//  StudentAppProfilxWorkingView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 9/10/23.
//
import SwiftUI
    // Define a custom view
    struct AppInfxView: View {
        var loadingState: LoadinxState // Assuming LoadinxState is an enum you've defined
        var appsInfo: Array<Appx> // Assuming AppInfo is a struct or class you've defined
        var appInfo: Appx
        var body: some View {
            HStack {
               if loadingState == .loaded && !appsInfo.isEmpty  {
                   AsyncImage(url: URL(string: appInfo.icon)) { image in
                       image.resizable()
                           .padding([.top, .leading, .bottom], 8)
                           .aspectRatio(contentMode: .fit)
                           .frame(width: 80, height: 80)
                   } placeholder: {
                       ProgressView()
                   }
                       //                            .frame(width: 50, height: 50)
                       //                            .padding([.leading])
               } else if loadingState == .loading {
                   ProgressView()
               } else {
                   Text("Failed to load data")
               }
               VStack(alignment: .leading) {
                   if loadingState == .loaded && !appsInfo.isEmpty {
                       Text(appInfo.name)
                           .lineLimit(1)
                           .padding(.horizontal, 8)
                   } else if loadingState == .loading {
                       ProgressView()
                   } else {
                       Text("Failed to load data")
                   }
                   Text(appInfo.description ?? "")
                       .foregroundColor(.gray)
                       .font(.footnote)
                       .lineLimit(3, reservesSpace: true)
                   Spacer()
               }
           }
           .frame(width: 300)
           .background(Color.gray.opacity(0.2))
           .cornerRadius(10)
        }
    }
enum LoadinxState {
    case loading, loaded, failed
}
//  MARK: -
struct StudentAppProfilxWorkingView {
  
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var appxViewModel: AppxViewModel
    @State var noShow = true
    //  MARK:  Properties
    @State private var selectedDay = DayOfWeek.sunday
    @State var studentId: Int
    @State var studentName: String
    //  MARK: Manage Student Profile
    
//    @State var studentAppProfilefiles: [StudentAppProfilex]
    @StateObject var profileManager                         : StudentAppProfileManager = StudentAppProfileManager()
    @StateObject var studentAppprofile                      = StudentAppProfilex()
    @State var currentDayStudentAppProfile: DailySessions   = DailySessions.makeDefaultDailySession()
    //  MARK: Properties to help with processes
    @State var currentDayStudentAppProfileSave: DailySessions = DailySessions.makeDefaultDailySession()
    //  MARK:  Control the popup
    @State var presentMakeAppProfile: Bool  = false
    @State var timeOfDay                    = TimeOfDay.am
    @State var appCode = ""
    @State private var selectedSession: Session?
    @State var appsAMinfo: Array<Appx> = []
    @State var appsPMinfo: Array<Appx> = []
    @State var appsHomeinfo: Array<Appx> = []
    //     FIXME: Not sure, need to check if i need it and how to structure it
    @State private var isEditing: Bool = false
    @State var loadingState = LoadinxState.loading
    @State private var selectedOption: Int = 0
    @State private var data = ["One", "Two", "Three", "Four", "Five"]
    @State var lineToDisplay = ""
}
//  MARK: - extension for all the views and modifiers
extension StudentAppProfilxWorkingView: View {
    //  MARK: - headerView - Top subview
    var headerView: some View {
        Group {
            Picker("Select a day of the week", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id:\.self) { day in
                    Text(day.asAString).tag(day.rawValue)
                }
            }.pickerStyle(.segmented)
                .padding([.top, .horizontal] )
        }
        .navigationTitle(studentName)
    }
    var appSelectedViewAM:    some View {
        HStack {
            if loadingState == .loaded && !appsAMinfo.isEmpty  {
                AsyncImage(url: URL(string: appsAMinfo[0].icon)) { image in
                     image.resizable()
                 } placeholder: {
                     ProgressView()
                 }
                 .frame(width: 50, height: 50)
                 .padding([.leading])
            } else if loadingState == .loading {
                ProgressView()
            } else {
                Text("Failed to load data")
            }
            VStack(alignment: .leading) {
                if loadingState == .loaded && !appsAMinfo.isEmpty {
                    Text(appsAMinfo[0].name)
                } else if loadingState == .loading {
                    ProgressView()
                } else {
                    Text("Failed to load data")
                }
                Text("this is just a small description of the app and it should go from one side to the other")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
    //  MARK: -  the sub view for the am group
    var multipleAppsViewAM : some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(appsAMinfo) { appInfo in
                        //                    AppInfxView(loadingState: loadingState, appsAMinfo: appsAMinfo, appInfo: appInfo)
                    AppInfxView(loadingState: loadingState, appsInfo: appsAMinfo, appInfo: appInfo)
                }
                .padding(8)
            }
        }
    }
        //  MARK: -  the sub view for the am group
        var multipleAppsViewAMold : some View {
            Group {
                Text("Apps")
                    .font(.subheadline)
                if loadingState == .loaded && !appsAMinfo.isEmpty  {
                Picker("jjjjjj", selection: $selectedOption) {
                    ForEach(0..<appsAMinfo.count) { index in
                        let originalName = appsAMinfo[index].name
                        let truncatedName = String(originalName.prefix(30))
                        let displayName = originalName.count > 30 ? truncatedName + "..." : originalName
                        Text(displayName).tag(index)
    //                    Text(String(appsAMinfo[index].name.prefix(30))).tag(index)
                    }
                }
                .tint(.black)
                .frame(maxWidth: .infinity, alignment: .leading).border(.black, width: 1)
                .onChange(of: selectedOption) { newValue in
                    lineToDisplay =  appsAMinfo[newValue].name
                }
            } else if loadingState == .loading {
                ProgressView()
            } else {
                Text("Failed to load data")
            }
                Text(lineToDisplay)
            }
        }
    var amGroupView: some View {
        GroupBox {
            VStack(alignment: .leading) {
                if appsAMinfo.count == 1 {
                    appSelectedViewAM
                } else if appsAMinfo.count > 1{
                    multipleAppsViewAM
                }
//                appSelectedViewAM
                HStack {
                    Text("Minutes: \(55, specifier: "%.f")   ")
                        .font(.headline)
                        .bold()
                    Slider(value: $currentDayStudentAppProfile.amSession.sessionLength, in: 5...60, step: 5.0){
                        Text("Slider")
                    } minimumValueLabel: {
                        Text("5")
                    } maximumValueLabel: {
                        Text("60")
                    } onEditingChanged: { editing in
                        if !editing {
                            // This code will be executed when the user has finished interacting with the slider
                            print("Slider interaction finished. Current value: \(currentDayStudentAppProfile.amSession.sessionLength)")
                            // Add any logic you need to handle the final slider value here
                        }
//                        isEditing = editing
                    }
//                    .onChange(of: currentDayStudentAppProfile.amSession.sessionLength) { newValue in
//                        // This code will be executed whenever the slider's value changes
//                        print("Slider value changed to \(newValue)")
//                        // You can add any other logic you need here
//                    }
//                    .disabled(true)
                }
//                Toggle("Single App", isOn: $currentDayStudentAppProfile.amSession.oneAppLock)
//                    .disabled(true)
            }
        } label: {
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
    var appSelectedViewPM:    some View {
        HStack {
            if loadingState == .loaded && !appsPMinfo.isEmpty  {
                AsyncImage(url: URL(string: appsPMinfo[0].icon)) { image in
                     image.resizable()
                 } placeholder: {
                     ProgressView()
                 }
                 .frame(width: 50, height: 50)
                 .padding([.leading])
            } else if loadingState == .loading {
                ProgressView()
            } else {
                Text("Failed to load data")
            }
//            Image("iconImage")
//                .resizable()
//                .frame(width: 64, height: 64, alignment: .center)
//                .padding([.top, .trailing])
            VStack(alignment: .leading) {
                if loadingState == .loaded && !appsPMinfo.isEmpty {
                    Text(appsPMinfo[0].name)
                } else if loadingState == .loading {
                    ProgressView()
                } else {
                    Text("Failed to load data")
                }
//                Text(appsPMinfo[0].name)
//                    .bold()
                Text("this is just a small description of the app and it should go from one side to the other")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
    var multipleAppsViewPM : some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(appsPMinfo) { appInfo in
                        //                    AppInfxView(loadingState: loadingState, appsAMinfo: appsAMinfo, appInfo: appInfo)
                    AppInfxView(loadingState: loadingState, appsInfo: appsPMinfo, appInfo: appInfo)
                }
                .padding(8)
            }
        }
    }
    var pmGroupView: some View {
        GroupBox {
            VStack(alignment: .leading) {
                if appsPMinfo.count == 1 {
                    appSelectedViewPM
                } else if appsPMinfo.count > 1{
                    multipleAppsViewPM
                }
//                appSelectedViewPM
                HStack {
                    Text("Minutes: \(55, specifier: "%.f")   ")
                        .font(.headline)
                        .bold()
                    Slider(value: $currentDayStudentAppProfile.pmSession.sessionLength, in: 5...60, step: 5.0){
                        Text("Slider")
                    } minimumValueLabel: {
                        Text("5")
                    } maximumValueLabel: {
                        Text("60")
                    } onEditingChanged: { editing in
                        isEditing = editing
                    }
                    .disabled(true)
                }
//                Toggle("Single App", isOn: $currentDayStudentAppProfile.pmSession.oneAppLock)
//                    .disabled(true)
            }
        }label: {
            HStack {
                Text("**PM:** 12:00- 4:59 ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    timeOfDay = .pm
                    currentDayStudentAppProfileSave = currentDayStudentAppProfile
                    presentMakeAppProfile.toggle()
                } label: {
                    Text("Set It 🔆")
                }
            }.padding(.bottom)
        }
        .padding()
    }
   var appSelectedViewHome:    some View {
        HStack {
            if loadingState == .loaded && !appsHomeinfo.isEmpty  {
                AsyncImage(url: URL(string: appsHomeinfo[0].icon)) { image in
                     image.resizable()
                 } placeholder: {
                     ProgressView()
                 }
                 .frame(width: 50, height: 50)
                 .padding([.leading])
            } else if loadingState == .loading {
                ProgressView()
            } else {
                Text("Failed to load data")
            }
            VStack(alignment: .leading) {
                if loadingState == .loaded && !appsHomeinfo.isEmpty {
                    Text(appsHomeinfo[0].name)
                } else if loadingState == .loading {
                    ProgressView()
                } else {
                    Text("Failed to load data")
                }
                Text("this is just a small description of the app and it should go from one side to the other")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
    //  MARK: -  the sub view for the home group
    var multipleAppsViewHome : some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(appsHomeinfo) { appInfo in
                    AppInfxView(loadingState: loadingState, appsInfo: appsHomeinfo, appInfo: appInfo)
                }
                .padding(8)
            }
        }
    }
    var homeGroupView: some View {
        GroupBox {
            VStack(alignment: .leading) {
                if appsHomeinfo.count == 1 {
                    appSelectedViewHome
                } else if appsHomeinfo.count > 1{
                    multipleAppsViewHome
                }
//                appSelectedViewHome
                HStack {
                    Text("Minutes: \(55, specifier: "%.f")   ")
                        .font(.headline)
                        .bold()
                    Slider(value: $currentDayStudentAppProfile.homeSession.sessionLength, in: 5...60, step: 5.0){
                        Text("Slider")
                    } minimumValueLabel: {
                        Text("5")
                    } maximumValueLabel: {
                        Text("60")
                    } onEditingChanged: { editing in
                        isEditing = editing
                    }
                    .disabled(true)
                }
//                Toggle("Single App", isOn: $currentDayStudentAppProfile.homeSession.oneAppLock)
//                    .disabled(true)
            }
        } label: {
            HStack {
                Text("**Home:** 5:00 - ...")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                                            timeOfDay = .home
                                            currentDayStudentAppProfileSave = currentDayStudentAppProfile
                                            presentMakeAppProfile.toggle()
                } label: {
                    Text("Set It 🔆")
                }
            }.padding(.bottom)
        }
        .padding()
    }
    //  MARK: - mainview - Top subview
    var mainView: some View {
        Group {
            amGroupView
            pmGroupView
            homeGroupView
        }
    }
    //  MARK: - mainview - Top subview
    var body: some View {
//        if  loadingState == .loaded {
        ScrollView {
            if noShow == false &&  loadingState == .loaded {
                VStack(alignment: .leading, spacing: 8) {
                    headerView
                    mainView
                }
                    //                .frame(width: 380)
                .frame(width: UIScreen.main.bounds.width * 1.0)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $presentMakeAppProfile, onDismiss: {
            print("~~ dismissed makeAppProfile")
            if currentDayStudentAppProfile != currentDayStudentAppProfileSave {
                print(" they are not equal")
                upDateStudentAppProfile()
                profileManager.updateStudentAppProfile(newProfile: studentAppprofile)
//                profileManager.saveProfiles()
                print("~~ dismissed makeAppProfile second")
                Task {
                    do {
                        loadingState = .loading
                        await proceesAppCodes()
                        loadingState = .loaded
                    } catch {
                        loadingState = .failed
                    }
                }
            } else {
                print("they are equal")
            }
        })
        {
                   CategoryDisclosureView(selectedSession  : $selectedSession,
                                          isSheetPresented : $presentMakeAppProfile,
                                          sessionLength    : getSessionLengthBinding(),
                                          oneAppLock       : getoneAppLockBinding(),
                                          appCode          : $appCode,
                                          apps             : getappsBinding() )
               }
        .onAppear {
            
            Task {
                /* I took this out*/
//                studentAppProfilefiles = await  StudentAppProfileManager.loadProfilesx()
//                if let studentFound = studentAppProfilefiles.first { $0.id == studentId} {
//                    studentAppprofile.id          = studentFound.id
//                    studentAppprofile.locationId  = studentFound.locationId
//                    studentAppprofile.sessions    = studentFound.sessions
//                }
              await studentAppprofile.setStudentProfile(studentID: studentId)
              print("--- Finishe Loading in setStudentProfile")
              let user = getTheStudent(studentID: studentId)
              studentName = user.firstName + " " + user.lastName
              print(studentName)
              print("pause")
              

                /* I took this out  -- */
//                profileManager.studentAppProfileFiles    = studentAppProfilefiles
                let calendar                             = Calendar.current
                let dayNbr                               = calendar.component(.weekday, from: Date())
                guard let shortWeekdayText               = DayOfWeek(rawValue: dayNbr) else {fatalError()}
                setCurrentDateWith(shortWeekdayText.asAString)
                // Setting selectedDay will trigger .onChange which calls proceesAppCodes()
                selectedDay                              = DayOfWeek(rawValue: dayNbr)!
            }
        }
        .onChange(of: selectedDay) { newValue in
            setCurrentDateWith(newValue.asAString)
            Task {
                do {
                    loadingState = .loading
                    await proceesAppCodes()
                    loadingState = .loaded
                    noShow = false
                } catch {
                    loadingState = .failed
                }
            }
        }
    }
}
//  MARK: - extension for methods that communicate to popup View
extension StudentAppProfilxWorkingView {
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
//  MARK: - extension for methods that do work
extension StudentAppProfilxWorkingView {
    func proceesAppCodes() async  {
        appsAMinfo = currentDayStudentAppProfile.amSession.apps.compactMap { bundleId in
            appxViewModel.appx.first { $0.bundleId == bundleId }
        }

        appsPMinfo = currentDayStudentAppProfile.pmSession.apps.compactMap { bundleId in
            appxViewModel.appx.first { $0.bundleId == bundleId }
        }

        appsHomeinfo = currentDayStudentAppProfile.homeSession.apps.compactMap { bundleId in
            appxViewModel.appx.first { $0.bundleId == bundleId }
        }
    }
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
  
  func getTheStudent(studentID: Int) -> User {
    var user = User.makeDefault()
    do {
      user = try usersViewModel.getWithId(studentId)
//        let user = try getWithId(1)
        print("Found user: \(user)")
    } catch UserError.userNotFound {
        print("User not found")
    } catch {
        print("An unexpected error occurred: \(error)")
    }
    return user

  }
}
  // Mock User Data
  extension User {
      static func makeMockUser(
          id: Int,
          locationId: Int = 101,
          deviceCount: Int = 1,
          email: String = "example@example.com",
          groupIds: [Int] = [1, 2],
          groups: [String] = ["Group A", "Group B"],
          teacherGroups: [Int] = [101, 102],
          firstName: String,
          lastName: String,
          username: String = "username",
          notes: String = "No additional notes.",
          modified: String = "2023-08-04"
      ) -> User {
          return User(
              id: id,
              locationId: locationId,
              deviceCount: deviceCount,
              email: email,
              groupIds: groupIds,
              groups: groups,
              teacherGroups: teacherGroups,
              firstName: firstName,
              lastName: lastName,
              username: username,
              notes: notes,
              modified: modified
          )
      }
  }

  // Mock ViewModel
  class MockUsersViewModel: ObservableObject {
      @Published var users: [User] = [
//          User.makeMockUser(id: 1, firstName: "John", lastName: "Doe"),
//          User.makeMockUser(id: 2, firstName: "Jane", lastName: "Smith")
      ]
      
      func getWithId(_ id: Int) throws -> User {
          if let user = users.first(where: { $0.id == id }) {
              return user
          } else {
              throw UserError.userNotFound
          }
      }
  }

  // Mock Data for other required types like Appx
  extension Appx {
      static func makeMockAppx() -> Appx {
        Appx(id: 123, locationId: 1, isBook: false, bundleId: "wkmdknk.wlwjj", icon: "https://example.com/icon.png", name:  "Mock App", description: "This is a mock app description.")
      }
  }



  // Preview provider
  struct StudentAppProfilxWorkingView_Previews: PreviewProvider {
      static var previews: some View {
          Group {
              // Example with specific studentId and studentName
              StudentAppProfilxWorkingView(studentId: 3, studentName: "John Doe",  profileManager: StudentAppProfileManager()) // Replace with actual default values
                  .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
                  .previewDisplayName("iPad Pro (12.9-inch)")
                  .previewLayout(.fixed(width: 1024, height: 1366)) // Landscape
              // Other device previews...
          }
      }
  }


// Mock User Data



//    // Preview provider
//    struct StudentAppProfilxWorkingView_Previews: PreviewProvider {
//        static var previews: some View {
//            Group {
//                // Preview for iPad Pro (12.9-inch)
//                StudentAppProfilxWorkingView(profileManager: StudentAppProfileManager()) // Add other required initializers
//                    .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
//                    .previewDisplayName("iPad Pro (12.9-inch)")
//                    .previewLayout(.fixed(width: 1024, height: 1366)) // Landscape
//
//                // Preview for iPad Pro (12.9-inch) in Portrait
//                StudentAppProfilxWorkingView(profileManager: StudentAppProfileManager()) // Add other required initializers
//                    .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
//                    .previewDisplayName("iPad Pro (12.9-inch) Portrait")
//                    .previewLayout(.fixed(width: 1366, height: 1024)) // Portrait
//
//                // Preview for iPhone 12
//                StudentAppProfilxWorkingView(profileManager: StudentAppProfileManager()) // Add other required initializers
//                    .previewDevice(PreviewDevice(rawValue: "iPhone 12"))
//                    .previewDisplayName("iPhone 12")
//                    .previewLayout(.device)
//            }
//        }
//    }
//struct StudentAppProfilxWorkingView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentAppProfilxWorkingView()
//    }
//}
