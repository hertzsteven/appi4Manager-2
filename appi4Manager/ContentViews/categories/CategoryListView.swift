//
//  DynamiclyCreateLazyItemView.swift
//  button Background
//
//  Created by Steven Hertz on 6/11/23.
//

import SwiftUI

struct CategoryListView: View {
    
    @EnvironmentObject var appsViewModel : AppsViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel

    //    @EnvironmentObject var model: ViewModel
//    @StateObject    var categoryViewModel:          CategoryViewModel = CategoryViewModel()
    @State private  var popUpSheetSw:   Bool  = false
    @State private  var favoriteColor:  Int  = 0
    @State var path: NavigationPath = NavigationPath()
   
    @State          var newAppCategory: AppCategory
    @State private  var isAddingNewAppCategory = false
    
        
    var body: some View {
//        NavigationStack(path:$path ) {
            VStack {
               // LazyGrid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(categoryViewModel.appCategories, id: \.self) { item in
                            NavigationLink(value: item) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(height: 100)
                                        .foregroundColor(Color(UIColor(red: item.colorRGB.red, green: item.colorRGB.green, blue: item.colorRGB.blue, alpha: item.colorRGB.alpha)))
                                        .padding([.leading, .trailing], 6)
                                        .shadow(color: .gray, radius: 3)
                                        .overlay(
                                            VStack(alignment: .leading) {
                                                Image(systemName: item.symbolName)
                                                    .font(.title)
                                                    .padding(.bottom, 6)
                                                Text(item.title)
                                                    .font(.body)
                                            }
                                                .foregroundColor(.white)
                                                .padding(.leading, 16 ).padding(.bottom, 16)
                                            ,
                                            alignment: .bottomLeading
                                        )
                                        .offset(x: /*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/)
                                    Button(action: {
                                        print("just print")
                                    })  {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 30, height: 30)
                                            .offset(x: -87, y: -40)
                                    }
                                    .opacity(0.0)
                                }
                            }
                        }
                    }
                    .padding()
                    
                        // SPACER
                    Spacer()
                }
            }
            
            .onAppear {
                dump(appsViewModel.apps)
                print("dd")
//                model.loadSomeSamples()
            }
            
//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
            .sheet(isPresented: $isAddingNewAppCategory) {
                NavigationView {
                    CategoryEditorContView(appCategoryInitialValues: newAppCategory
                                          , appCategory: newAppCategory
                                          , appsViewModel: appsViewModel
//                                          , categoryViewModel: categoryViewModel
                                          , isNew: true
                    )
                }
                .presentationDetents( [ .large ] )
            }
            
//      MARK: -Navigation  * * * * * * * * * * * * * * * * * * * * * * * *
            .navigationDestination(for: AppCategory.self) { theappCategory in
                CategoryEditorContView(appCategoryInitialValues: theappCategory
                                       , appCategory: theappCategory
                                       , appsViewModel: appsViewModel
//                                       categoryViewModel: categoryViewModel
                )
            }

            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newAppCategory             = AppCategory.makeDefault()
                        isAddingNewAppCategory     = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .frame(height: 96, alignment: .trailing)
                }
            }

//        }
    }
    
   private var addButton: some View {
       Button {
           popUpSheetSw = true
       } label: {
           Image(systemName: "plus")
                           .imageScale(.large)
       }
   }
}


struct DynamiclyCreateLazyItemView_Previews: PreviewProvider {
    @State var path: NavigationPath

    static var previews: some View {
        CategoryListView( newAppCategory: AppCategory.makeDefault())
    }
}

