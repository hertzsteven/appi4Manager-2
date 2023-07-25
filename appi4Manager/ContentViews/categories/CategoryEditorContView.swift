//
//  CategoryEditorContView.swift
//  button Background
//
//  Created by Steven Hertz on 6/13/23.
//

import SwiftUI

struct CircleView: View {
    var color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 100, height: 100)
            .padding(. horizontal,40)
    }
}

struct DeleteButtonViewCTG: View {
    
    var action: () -> Void
    
    var body: some View {
        Button(role: .destructive) {
            action()
        }
    label: {
        Text("Delete")
            .foregroundColor(.white)
            .bold()
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(10)
    }
    .buttonStyle(PlainButtonStyle())
    .frame(maxWidth: .infinity)
    .listRowInsets(EdgeInsets())
    }
}


struct CollapsibleListCTG: View {
    @EnvironmentObject var model: CategoryViewModel
    @EnvironmentObject var appsViewModel : AppsViewModel
    @Environment(\.editMode) var editMode
    
    @Binding var isListVisible: Bool
    @Binding var newItem: String
    @Binding var listData:   [String]
    let title:      String
    let appArray: [Apps]
    
    var action: () -> Void
    
    var itIsInEdit: Bool {
        editMode?.wrappedValue == .active
    }
    
    var body: some View {
        
        Section(header: HStack {
       
            TextField("Update \(title)", text: $newItem)
            Spacer()
       
//            if itIsInEdit {
                Button {
                    action()
                } label: {
                    Image(systemName: "plusminus")
                }
                Divider()
//            }
       
            Button {
                isListVisible.toggle()
            } label: {
                Image(systemName: isListVisible ? "chevron.down" : "chevron.right")
            }
        }) { if isListVisible {
            
            ForEach(listData.map({ id in
//                appsViewModel.apps.first(where: { $0.id == id })!
                appArray.first(where: { $0.id == id })!
            }), id: \.id) { app in
                Label("\(app.title)", systemImage: app.symbolName)
//                Text("\(app.title)")
                    .foregroundColor(itIsInEdit ? .black :  Color(.darkGray))
            }
            .onAppear{
                print("wait")
                print(listData)
                print("ok")
            }

        }
        }


    }
}


//struct AnimateTextField: View {
//    @Binding var textField: String
//    @Binding var mode : EditMode
//    var itIsInEdit: Bool {
//        mode == .active
//    }
//    let label: String
//
//    var body: some View {
//
//        HStack {
//            if !textField.isEmpty {
//                Text("\(label): ")
//            }
//
//            ZStack(alignment: .leading) {
//                TextField(label, text: $textField)
//                    .opacity(itIsInEdit ? 1 : 0)
//                Text(textField)
//                    .opacity(itIsInEdit ? 0 : 1)
//                    .foregroundColor(Color(.darkGray))
//            }
//        }
//    }
//}


struct CategoryEditorContView: View {

//  added properties

    @State var isBlocking = false
    
    @State private var inUpdate = false
    @State private var inDelete = false
    @State private var inAdd    = false
    
    @State var mode: EditMode = .inactive
    
//    @State private var showDeleteAlert = false


//    @State var editMode = EditMode.inactive


    @State var selectedAppsSaved:       Array<Int> = []

    @State var passedItemSelected:      Array<String> = []

    @State var selectedApps:            Array<String> = []
    
    @State var appCategoryInitialValues: AppCategory
    @State private var toShowAppsList:  Bool = false


    @State var appCategory: AppCategory
    @State var selectedAppsInitialValues:   Array<Int> = []
    
//    @State private var isSheetPresented = false
    @State private var inCancelEdit = false
    @State private var inCancelAdd = false


//    @State private var appCategory_start   = AppCategory.makeDefault()  // this gets done by the update
//    @State private var appCategoryCopy     = AppCategory.makeDefault()

    @State private var isDeleted = false
    
    var itIsInEdit: Bool {
        mode == .active
    }

    
    
    private var isAppCategoryDeleted: Bool {
        // change to appCategory view model
    // !usersViewModel.exists(appCategoryInitialValues) && !isNew
    false
    }

// added properties end

//    @EnvironmentObject var apps2ViewModel : AppsViewModel
    
    @StateObject var appsViewModel : AppsViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
//    @StateObject var categoryViewModel: CategoryViewModel
    
    @State var selectedColor: Color =  CategoryColors.random()

//    @State var someText: String = ""
        
    @Environment(\.dismiss) private var dismiss

    @State var isNew = false
    
    var appCategorySelectedColor: Color {
        Color(UIColor(red: appCategory.colorRGB.red,
                      green: appCategory.colorRGB.green,
                      blue: appCategory.colorRGB.blue,
                      alpha: appCategory.colorRGB.alpha))
    }
    
    @State var isList1Visible: Bool = true
    @State var newItem1: String = ""
    @State private var toShowAppList: Bool = false
    @State private var sometext = ""
    
    
    
//    var buttonAction: () -> Void
    
    var body: some View {
            //        NavigationStack() {
        GeometryReader { geometry in
            Form {
                
                    //  Circle and Name
                Section {
                        // The Circle with 2 Spacer Views
                    HStack {
                        PopulateCircleView(selectedColor: $selectedColor, selectedSymbol: $appCategory.symbolName)
                    }
                        // The name field
                    EnterNameView(someText: $appCategory.title, mode: $mode, selectedColor: selectedColor )
                    
                }
                VStack {
                    SymbolPickerView(selectedSymbol: $appCategory.symbolName, selectedColor: $selectedColor, mode: $mode)
                } .frame(height: geometry.size.height / 4)
                    // My Color Picker with fixed colors
                ColorPickerViewView(selectedColor: $selectedColor, mode: $mode)
                
                    // Swift Color Picker View
                ColorPicker("Select a Custom Color", selection: $selectedColor)
                    .opacity(itIsInEdit ? 1 : 0.6)
                    .disabled(itIsInEdit ? false : true)
                
                
    
                
                CollapsibleListCTG(isListVisible: $isList1Visible, newItem: $newItem1, listData: $selectedApps, title: "Apps", appArray: appsViewModel.apps) {
                    Task {
                        do {
                            passedItemSelected = selectedApps
                            toShowAppList.toggle()
                        } catch {
                                // Handle error
                        }
                    }
                }
                .opacity(itIsInEdit ? 1 : 0.6)
                .disabled(itIsInEdit ? false : true)
                
                .environment(\.editMode, $mode)
                .onAppear {
                    print("=====================")
                dump(appsViewModel.apps)
                    print("===================")

                }
                if !isNew {
                    DeleteButtonViewCTG(action: {
                        inDelete.toggle()
                    })
                    .listRowInsets(EdgeInsets())
                    .disabled(!itIsInEdit ? true : false)
                }
                
            }
            
                //       MARK: - Navigation Configuration  * * * * * * * * * * * * * * * * * * * * * * * *
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            
            
                //       MARK: - Toolbar Configuration  * * * * * * * * * * * * * * * * * * * * * * * *
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isNew {
                        Button(!itIsInEdit ? "Edit" : "**Done**") {
                            if itIsInEdit {
                                if inUpdate {
                                    return
                                }
                                
                                Task {
                                    isBlocking = true
                                    
                                    do {
                                        inUpdate = true
                                        await upDateAppCategory()
                                        inUpdate = false
                                        isBlocking = false
                                        if !itIsInEdit {
                                                //                                                updateModeWithAnimation()
                                        } else {
                                            updateModeWithAnimation(switchTo: .inactive)
                                        }
                                    } catch {
                                        print("Failed in task")
                                    }
                                }
                            } else {
                                updateModeWithAnimation()
                            }
                        }.frame(height: 96, alignment: .trailing)
                            .disabled(isBlocking)
                    }
                }
                
                
                    //             Cancel button from editing not adding
                ToolbarItem(placement: .navigationBarLeading) {
                    if itIsInEdit && !isNew {
                        Button("Cancel") {
                            inCancelEdit.toggle()
                        }.frame(height: 96, alignment: .trailing)
                            .disabled(isBlocking)
                    }
                }
                
                
                ToolbarItem(placement: .cancellationAction) {
                    if isNew {
                        Button("Cancel") {
                            inCancelAdd = true
                        }
                    }
                }
                
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isNew {
                            if inAdd {
                                return
                            }
                            let uiColor = UIColor(selectedColor)
                            let rgba = uiColor.rgba
                            let newAppCTG = AppCategory(id: appCategory.id,
                                                        title: appCategory.title,
                                                        symbolName: appCategory.symbolName,
                                                        colorRGB: ColorRGB(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha),
                                                        appIds: selectedApps)
                            dump(newAppCTG)
                            
                            categoryViewModel.appCategories.append(newAppCTG)
                            
                            categoryViewModel.saveToUserDefaults()
                            dismiss()
                            
                        }
                    } label: {
                        Text(isNew ? "Add" : "")
                    }
                    .frame(height: 96, alignment: .trailing)
                    .disabled(appCategory.title.isEmpty)
                }
                
            }
            
            
                //      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
            .navigationBarBackButtonHidden(mode == .active ? true : false)
            
                //      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
            
            
                //       Select Students Popup
            .sheet(isPresented: $toShowAppList) {
                
                    //                    let userFilter2: ((any ItemsToSelectRepresentable) -> Bool) = { usr in
                    //                        !teacherIds.contains(usr.id)
                    //                    }
                
                let userFilter2: ((any ItemsToSelectRepresentableStr) -> Bool)? = nil
                NavigationView {
                    ItemListSelectViewStr(passedItemSelected: $passedItemSelected,
                                       itemsToList: appsViewModel.apps,
                                       itemFilter2: userFilter2,
                                       listTitle: "Select the apps for the category")
                }
                .onDisappear {
                    print(passedItemSelected)
                    selectedApps = passedItemSelected
                    print(passedItemSelected)
                    appCategory.appIds = selectedApps
                }
            }
            
            
            
            
            
                //       MARK: - Confirmation Dialog  * * * * * * * * * * * * * * * * * * * * * * * *
            
            .confirmationDialog("Are you sure you want to delete this class?", isPresented: $inDelete) {
                Button("Delete the Student", role: .destructive) {
                    deleteTheAppCategory()
                }
            }
                // from edit
            .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelEdit, titleVisibility: .visible) {
                Button("Discard Changes edit ", role: .destructive) {
                        // Do something when the user confirms
                    mode            = .inactive
                    appCategory     =  appCategoryInitialValues
                    selectedColor   = Color(UIColor(red: appCategory.colorRGB.red,
                                                    green: appCategory.colorRGB.green,
                                                    blue: appCategory.colorRGB.blue,
                                                    alpha: appCategory.colorRGB.alpha)
                    )
                    selectedApps    = appCategory.appIds
                }
            }
            
                // from add
            .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelAdd, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) {
                        // Do something when the user confirms
                    dismiss()
                }
            }
            
                // -------
                //           }
            .onAppear {
                print("-----------------------")
            dump(appsViewModel.apps)
                print("-----------------------")
                selectedColor = Color(UIColor(red: appCategory.colorRGB.red,
                                              green: appCategory.colorRGB.green,
                                              blue: appCategory.colorRGB.blue,
                                              alpha: appCategory.colorRGB.alpha)
                )
                    //                usersViewModel.ignoreLoading = true
                
                if !isNew {
                    toDoWithNewAppCategoryToProcess()
                } else {
                    mode = .active
                }
            }
            .onDisappear{
                mode = .inactive
            }
        }
    }
}



//  MARK: -  View Components

struct PopulateCircleView: View {
    @Binding var selectedColor: Color
    @Binding var selectedSymbol: String
    
    var body: some View {
        Spacer()
         CircleView(color: selectedColor)
             .overlay(alignment: .center) {
                 Image(systemName: selectedSymbol)
                     .foregroundColor(.white)
                     .font(.title)
                     .bold()
         }
         Spacer()
    }
}

struct EnterNameView: View {
    
    @Binding var someText: String
    @Binding var mode: EditMode
    let selectedColor: Color
    
    var body: some View {
        AnimateTextField(textField: $someText, mode: $mode, label: "Title")
//        TextField("Name", text: $someText)
//            .font(.PoppinsBold(size: 24))
            .opacity(1.0)
            .multilineTextAlignment(.center)
            .foregroundColor(selectedColor)
            .padding()
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .padding([.top, .bottom])
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
    }
}

struct ColorButton: View {
    let color: Color
    @Binding var selectedColor: Color
    
    var body: some View {
        Button(action: {
            selectedColor = color
        }) {
            GeometryReader { geometry in
                Circle()
                    .fill(color)
                    .overlay(
                        Circle()
                            .stroke(selectedColor == color ? Color.gray : Color.clear, lineWidth: 2)
                            .opacity(0.8)
                            .animation(
                                .easeInOut(duration: 0.6),
                                value: selectedColor == color
                            )
                        .frame(width: geometry.size.width + 8, height: geometry.size.height + 8)
                    )
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}


//struct ColorButton2: View {
//    let color: Color
//    @Binding var selectedColor: Color
//
//    var body: some View {
//        Button(action: {
//            selectedColor = color
//        }) {
//            Circle()
//                .fill(color)
//                .frame(width: 50, height: 50)
//                .overlay(
//                    Circle()
//                        .stroke(selectedColor == color ? Color.gray : Color.clear, lineWidth: 2)
//                        .opacity(0.8)
//                        .animation(
//                            .easeInOut(duration: 0.6),
//                            value: selectedColor == color
//                        )
//                    .frame(width: 60, height: 60)
//                )
//        }
//    }
//}

struct ColorPickerViewView: View {
    
    @Binding  var selectedColor: Color
    @Binding  var mode: EditMode
    var itIsInEdit: Bool {
        mode == .active
    }


    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(CategoryColors.all, id: \.self) { clr in
                    ColorButton(color: clr, selectedColor: $selectedColor)
                        .opacity(itIsInEdit ? 1 : 0.6)
                        .disabled(itIsInEdit ? false : true)
                }
            }.padding()
        }
    }
}

//struct SymbolPickerView2: View {
//
//    @State private var symbolNames = CategorySymbols.symbolNames
//    @Binding var selectedSymbol: String
//    var columns = Array(repeating: GridItem(.flexible()), count: 6)
//
//    @Binding  var selectedColor: Color
//
//    var body: some View {
//        ScrollView {
////            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 16) {
//            LazyVGrid(columns: columns) {
//                ForEach(symbolNames, id: \.self) { symbolItem in
//                    Button {
//                        selectedSymbol = symbolItem
//                    } label: {
//                        Image(systemName: symbolItem)
//                            .imageScale(.large)
//                            .foregroundColor(selectedColor)
//                            .padding(5)
//                            .overlay(
//                                Circle()
//                                    .stroke(selectedSymbol == symbolItem ? Color.gray : Color.clear, lineWidth: 2)
//                                    .opacity(0.8)
//                                    .animation(
//                                        .easeInOut(duration: 0.6),
//                                        value: selectedSymbol == symbolItem
//                                    )
//                                .frame(width: 40, height: 40)
//
//                             )
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
////            .drawingGroup()
//        }
//        .onAppear {
////            selectedColor = Color(.blue)
//        }
//
//    }
//}

struct SymbolPickerView: View {
    
    @State private var symbolNames = CategorySymbols.symbolNames
    @Binding var selectedSymbol: String

    var columns = Array(repeating: GridItem(.flexible()), count: 6)

    @Binding  var selectedColor: Color
    @Binding  var mode: EditMode
    var itIsInEdit: Bool {
        mode == .active
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(symbolNames, id: \.self) { symbolItem in
                    Button {
                        selectedSymbol = symbolItem
                    } label: {
                        GeometryReader { geometry in
                            Image(systemName: symbolItem)
                                .imageScale(.large)
                                .foregroundColor(selectedColor)
                                .padding(10)
                                .opacity(itIsInEdit ? 1 : 0.6)
                                .disabled(itIsInEdit ? false : true)
                                .overlay(
                                    Circle()
                                        .stroke(selectedSymbol == symbolItem ? Color.gray : Color.clear, lineWidth: 2)
                                        .opacity(0.8)
                                        .animation(
                                            .easeInOut(duration: 0.6),
                                            value: selectedSymbol == symbolItem
                                        )
                                        .frame(width: geometry.size.width + 4, height: geometry.size.height + 4)
                                )
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .padding(5)
                    }
                    .opacity(itIsInEdit ? 1 : 0.6)
                    .disabled(itIsInEdit ? false : true)

                    .buttonStyle(.plain)
                }
            }
        }
    }
}


extension CategoryEditorContView {
    
    fileprivate func updateModeWithAnimation(switchTo theMode: EditMode = .active) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mode = theMode
        }
    }

    // This is what
    func toDoWithNewAppCategoryToProcess()  {
        selectedApps = appCategory.appIds
        getAppCategoryDetail()
        storeAppCategoryDetailStartingPoint()
        mode = .inactive
    }
     
    fileprivate func getAppCategoryDetail() {
    
/*
 - Seems that all the User information is already retreived and no further retrevila is required,
 - this is different from the class detail where we needed o retreive class detail info
 - the only question is the picture
 */
//        storeAppCategoryDetailStartingPoint()
//        Task {
//            do {
//                    // get the class info
//                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: schoolClass.uuid))
//
//                    // retreive the students into View Model
//                self.classDetailViewModel.students = classDetailResponse.class.students
//                self.classDetailViewModel.teachers = classDetailResponse.class.teachers
//
//                storeUserDetailStartingPoint()
//
//
//            } catch let error as ApiError {
//                    //  FIXME: -  put in alert that will display approriate error message
//                print(error.description)
//            }
//        }

    }
    
    fileprivate func storeAppCategoryDetailStartingPoint() {
        
// save for restore and compare
        appCategoryInitialValues = appCategory
        
        /*
         // put the ids into selected students array
         selectedStudentClasses = user.groupIds
         selectedTeacherClasses = user.teacherGroups
         
         */
    }
}



extension CategoryEditorContView {
    
    fileprivate func addTheAppCategory() {
         if isNew {
/*
         
 //        setup properties of AppCategory for doing the add
             user.username  = String(Array(UUID().uuidString.split(separator: "-")).last!)
             user.locationId = appWorkViewModel.currentLocation.id
             user.groupIds   = [appWorkViewModel.getIDpicClass()]
             Task {
                 do {
                     let resposnseaddAAppCategory: AddAAppCategoryResponse = try await ApiManager.shared.getData(from: .addUsr(user: user))
                     
                     user.id = resposnseaddAAppCategory.id
                     await imagePicker.loadTransferable2Update(teachAuth: appWorkViewModel.getTeacherAuth(), studentId: user.id)


 //                   add user into existing user array
                     self.usersViewModel.users.append(self.user)

 //                 trigger a refresh of screen and not getting the image from cacheh
                     self.appWorkViewModel.uniqueID = UUID()

                 } catch let error as ApiError {
                         //  FIXME: -  put in alert that will display approriate error message
                     print(error)
                 }
             }
         
 */
         }
     }
    
    fileprivate func deleteTheAppCategory() {
//        print("we are about to delete the user \(user.id)")
        
        let index = categoryViewModel.appCategories.firstIndex { appCtg in
            appCtg.id == appCategory.id
        }
        categoryViewModel.appCategories.remove(at: index!)
        
        categoryViewModel.saveToUserDefaults()

        isDeleted = true
 /*
       
        Task {
            do {
                print("break")
                let response = try await ApiManager.shared.getDataNoDecode(from: .deleteaAppCategory(id: user.id))
                dump(response)
                usersViewModel.delete(user)

                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
 */
        dismiss()
    }


    
    fileprivate func upDateAppCategory() async {
        
        let uiColor = UIColor(selectedColor)
        let rgba = uiColor.rgba
        
//        let updatedAppCategory = AppCategory(title: appCategory.title, symbolName: appCategory.symbolName, colorRGB: ColorRGB(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha))
        let updatedAppCategory = AppCategory(id: appCategory.id,
                                    title: appCategory.title,
                                    symbolName: appCategory.symbolName,
                                    colorRGB: ColorRGB(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha),
                                    appIds: selectedApps)

        let index = categoryViewModel.appCategories.firstIndex { appCtg in
            appCtg.id == appCategory.id
        }
        categoryViewModel.appCategories[index!] = updatedAppCategory
        
        categoryViewModel.saveToUserDefaults()
/*
         // update user in array of users being shown
        let index = usersViewModel.users.firstIndex { usr in
            usr.id == user.id
        }
        usersViewModel.users[index!] = user
        
        await imagePicker.loadTransferable2Update(teachAuth: appWorkViewModel.getTeacherAuth(), studentId: user.id)
        
        // update the student Pic
//        imagePicker.updateTheImage()
        
        // do housekeeping - start a new starting point
        storeAppCategoryDetailStartingPoint()
 */

    }
    
    
    fileprivate func restoreSavedItems() {
//        dump(user)
        print("pause")
        
            // put the ids into selected students array
//        selectedStudentClasses = user.groupIds
        
            // initialize the saved list
//        selectedStudentClassesSaved = selectedStudentClasses
        
        
//        selectedTeacherClasses = user.teacherGroups
        
            // initialize the saved list
//        selectedTeacherClassesSaved = selectedTeacherClasses
    }
}

struct CategoryEditorContView_Previews: PreviewProvider {
    static var previews: some View {
        // You need to initialize a CategoryViewModel and AppCategory object with some initial values for the preview.
        let categoryViewModel = CategoryViewModel()
        
        let appCategory = AppCategory(id: "1",
                                      title: "Test Category",
                                      symbolName: "star.fill",
                                      colorRGB: ColorRGB(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0),
                                      appIds: [])
        let appsViewModel = AppsViewModel()
        
        CategoryEditorContView(appCategoryInitialValues: appCategory,
                               appCategory: appCategory,
                               appsViewModel: appsViewModel)
            .environmentObject(appsViewModel)
            .environmentObject(categoryViewModel)  // Add this line
    }
}

