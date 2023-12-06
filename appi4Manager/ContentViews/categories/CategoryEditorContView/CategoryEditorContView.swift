//
//  CategoryEditorContView.swift
//  button Background
//
//  Created by Steven Hertz on 6/13/23.
//

import SwiftUI


struct CategoryEditorContView: View {

    @State var isBlocking = false
    
    @State private var inUpdate = false
    @State private var inDelete = false
    @State private var inAdd    = false
    
    @State var mode: EditMode = .inactive

    @State var selectedAppsSaved:       Array<Int> = []

    @State var passedItemSelected:      Array<Int> = []

    @State var selectedApps:            Array<Int> = []
    
    @State var appCategoryInitialValues: AppCategory
    @State private var toShowAppsList:  Bool = false


    @State var appCategory: AppCategory
    @State var selectedAppsInitialValues:   Array<Int> = []
    @State private var inCancelEdit = false
    @State private var inCancelAdd = false
    @State private var isDeleted = false
    
    var itIsInEdit: Bool {
        mode == .active
    }
    
    private var isAppCategoryDeleted: Bool {
        // change to appCategory view model
        // !usersViewModel.exists(appCategoryInitialValues) && !isNew
        false
    }

    @EnvironmentObject  var appxViewModel:     AppxViewModel
    @StateObject        var appsViewModel:      AppsViewModel
    @EnvironmentObject  var categoryViewModel:  CategoryViewModel
    @EnvironmentObject var appWorkViewModel : AppWorkViewModel
    @EnvironmentObject var teacherItems: TeacherItems


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
    
    @State private var hasError = false
    @State private var error: ApiError?


//    var buttonAction: () -> Void
    
    var body: some View {
            //        NavigationStack() {
        GeometryReader { geometry in
            ZStack {
                if appxViewModel.isLoaded == false {
                    VStack {
                        ProgressView().controlSize(.large).scaleEffect(2)
                    }
                } else {
                    
                    Form {
                        
                        Text(appxViewModel.appx.first?.name ?? "empty")
                        
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
                        }
                        .frame(height: geometry.size.height / 4)
                        
                            // My Color Picker with fixed colors
                        ColorPickerViewView(selectedColor: $selectedColor, mode: $mode)
                        
                        
                            // Swift Color Picker View
                        ColorPicker("Select a Custom Color", selection: $selectedColor)
                            .opacity(itIsInEdit ? 1 : 0.6)
                            .disabled(itIsInEdit ? false : true)
                        
                        
                        CollapsibleListCTG(isListVisible: $isList1Visible, newItem: $newItem1, listData: $selectedApps, title: "Apps", appArray: appxViewModel.appx) {
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
                                //                        print("in form on appaer")
                        }
                        
                            // delete button
                        if !isNew {
                            DeleteButtonViewCTG(action: {
                                inDelete.toggle()
                            })
                            .listRowInsets(EdgeInsets())
                            .disabled(!itIsInEdit ? true : false)
                        } // end of delete button
                        
                    } // end of form
                }
            }
            //       MARK: - Navigation Configuration  * * * * * * * * * * * * * * * * * * * * * * * *
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(mode == .active ? true : false)
            
            
            //       MARK: - Toolbar Configuration  * * * * * * * * * * * * * * * * * * * * * * * *

            .toolbar {
            
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isNew {
                        Button(action: {
                            itIsInEdit ? toolbarhandleEdit() : toolbarhandleDone()
                        }, label: {
                            Text(!itIsInEdit ? "Edit" : "Done")
                        })
                        .frame(height: 96, alignment: .trailing)
                        .disabled(isBlocking)
                    }
                }
                
                //   Cancel button from editing not adding
                ToolbarItem(placement: .navigationBarLeading) {
                    if itIsInEdit && !isNew {
                        Button("Cancel") {
                            inCancelEdit.toggle()
                        }.frame(height: 96, alignment: .trailing)
                            .disabled(isBlocking)
                    }
                }
                
                //   Cancel button from  adding
                ToolbarItem(placement: .cancellationAction) {
                    if isNew {
                        Button("Cancel") {
                            inCancelAdd = true
                        }
                    }
                }
                
                // doing an add
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if isNew {
                            toolbarhandleAdd()
                        }
                    }, label: {
                        Text(isNew ? "Add" : "")
                    })
                    .frame(height: 96, alignment: .trailing)
                    .disabled(appCategory.title.isEmpty)
                }
                
            }   // end of toolbar
            
            
            //      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
            
            
            //       Select app Popup
            .sheet(isPresented: $toShowAppList) {
                
                //                    let userFilter2: ((any ItemsToSelectRepresentable) -> Bool) = { usr in
                //                        !teacherIds.contains(usr.id)
                //                    }
                
                let userFilter2: ((any ItemsToSelectRepresentablewithPic) -> Bool)? = nil
                NavigationView {
                    ItemListSelectViewWithPic(passedItemSelected:  $passedItemSelected,
                                       itemsToList:          appxViewModel.appx,
                                       itemFilter2:          userFilter2,
                                       listTitle:            "Select the apps for the category")
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
//      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
            .task {
                guard appxViewModel.isLoaded == false else { return }
                if appxViewModel.ignoreLoading {
                    print("in ignore lloading")
                    appxViewModel.ignoreLoading = false
                        // Don't load the classes if ignoreLoading is true
                } else {
                        // Load the classes if ignoreLoading is false
                    print("in before await")
                    await loadTheapps()
                    appxViewModel.ignoreLoading = false
                }
                
            }
            .onAppear {
                selectedColor = Color(UIColor(red: appCategory.colorRGB.red,
                                              green: appCategory.colorRGB.green,
                                              blue: appCategory.colorRGB.blue,
                                              alpha: appCategory.colorRGB.alpha)
                )
                    //                usersViewModel.ignoreLoading = true
                print("in on appear")
                if !isNew {
                    toDoWithNewAppCategoryToProcess()
                } else {
                    mode = .active
                }
            }
            .onDisappear{
                mode = .inactive
            }
        } // end geomotry
    }
}

extension CategoryEditorContView {
    
    func loadTheapps() async {
        do {
            try await appxViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }

    
    // handle the edit done toolbarItem
    func toolbarhandleEdit() {
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
                    //updateModeWithAnimation()
                } else {
                    updateModeWithAnimation(switchTo: .inactive)
                }
            } catch {
                print("Failed in task")
            }
        }
    }

    func toolbarhandleDone() {
        updateModeWithAnimation()
    }
    
    func toolbarhandleAdd() {
        if inAdd {
            return
        }
        
        let uiColor = UIColor(selectedColor)
        let rgba = uiColor.rgba
        let newAppCTG = AppCategory(id: appCategory.id,
                                    title: appCategory.title,
                                    symbolName: appCategory.symbolName,
                                    colorRGB: ColorRGB(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha),
                                    appIds: selectedApps,
                                    locationId: teacherItems.currentLocation.id)
        
        dump(newAppCTG)
        
        categoryViewModel.appCategories.append(newAppCTG)
        FirestoreManager().writeAppCategory(appCategory: newAppCTG)
        
        categoryViewModel.saveToUserDefaults()
        dismiss()
    }
}

//  MARK: -  View Components


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
        
        FirestoreManager().deleteAppCategoryWith(appCategory.id)
        
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
                                             appIds: selectedApps, locationId: teacherItems.currentLocation.id)

        let index = categoryViewModel.appCategories.firstIndex { appCtg in
            appCtg.id == appCategory.id
        }
        categoryViewModel.appCategories[index!] = updatedAppCategory
        FirestoreManager().writeAppCategory(appCategory: updatedAppCategory)

        
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
        var appWorkViewModel = AppWorkViewModel()

        let appCategory = AppCategory(id: "1",
                                      title: "Test Category",
                                      symbolName: "star.fill",
                                      colorRGB: ColorRGB(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0),
                                      appIds: [], locationId: appWorkViewModel.currentLocation.id)
        let appsViewModel = AppsViewModel()
        
        CategoryEditorContView(appCategoryInitialValues: appCategory,
                               appCategory: appCategory,
                               appsViewModel: appsViewModel)
            .environmentObject(appsViewModel)
            .environmentObject(categoryViewModel)  // Add this line
    }
}

