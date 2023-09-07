    //
    //  CategoryDisclosureView.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 7/31/23.
    //

import SwiftUI

let indigo = UIColor(red: 0.294, green: 0.0, blue: 0.510, alpha: 1)


struct CardGroupBoxStyle: GroupBoxStyle {
    let bgclr: UIColor
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
        .padding()
        .background(Color(bgclr).opacity(0.3))

//
//        .background(Color(.systemGroupedBackground).opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}


struct LblExtractedSubview: View {
    let matchedApp: Appx
    
    var body: some View {
        Label {
            Text(" \(matchedApp.name)")
        } icon: {
            AsyncImage(url: URL(string: matchedApp.icon)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .padding([.leading])
        }
    }
}

struct HeaderGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
        .padding()
        .background(Color.orange.opacity(0.6))
        
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}


struct CategoryDisclosureView: View {
    @Binding var selectedSession: Session?
    @Binding var isSheetPresented: Bool
    
    @EnvironmentObject var appxViewModel :    AppxViewModel
    @EnvironmentObject var appWorkViewModel : AppWorkViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    @State var appSelected: Array<Int> = [] {
        didSet {
            print("^ count \(apps.count)")
            apps.removeAll()
            apps.append(contentsOf: appSelected)
            print("^ count \(apps.count)")
        }
    }
    
    @State var accumulatex: Double = 0

    var filteredData: [Appx] {
        appxViewModel.appx.filter { appSelected.contains($0.id) }
    }

    @State private var selectedSegment = 0
    @Binding var sessionLength          : Int
    @Binding var oneAppLock             : Bool
    @Binding var appCode                : Int
    @Binding var apps                   : [Int]
    
    var body: some View {
        
        if accumulatex > 0 {
            GroupBox {
//                appPickerView()
                Text(" the new app code selected\(appCode)")
                        Picker("Apps", selection: $selectedSegment) {
                            ForEach(appSelected, id: \.self) { appsel in
                                    //                        Text(appxViewModel.appx.filter { appSelected.contains($0.id) }[index].name).tag(index)
                                if let idx = appxViewModel.appx.firstIndex(where: { $0.id == appsel }) {
                                    HStack {
                                        Text(appxViewModel.appx[idx].name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            //                                Spacer()
                                    }
                                }
                            }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .pickerStyle(.menu)
                }
                Stepper("Session Length: \(sessionLength)", value: $sessionLength, in: 5...60, step: 5)
                
                HStack {
                    Toggle("Single App", isOn: $oneAppLock)
                    Button("Reset") {
                        withAnimation {
                            accumulatex = 0
                            appSelected.removeAll()
                            sessionLength = 20
                        }
                        
                    }
                }
            }  label: {
                HStack {
                    Text("**App Profile App Count:** \(appSelected.count)")
                    Spacer()
                    Button("Done") {
//                        withAnimation {
//                            accumulatex = 0
//                            appSelected.removeAll()
//                            lengthOfSesssion = 20
//                        }
                        selectedSession = Session(apps: appSelected, sessionLength: sessionLength, oneAppLock: oneAppLock)
                        isSheetPresented = false

                        
                    }
                }
            }
            .padding()
            .cornerRadius(12.0, antialiased: true)
            .opacity(accumulatex > 0 ? 1 : 0)
            .animation(Animation.easeInOut(duration: 2.0), value: accumulatex)
            .groupBoxStyle(HeaderGroupBoxStyle())
            
        }
        
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(categoryViewModel.filterCategoriesinLocation(appWorkViewModel.currentLocation.id)) { catg in
                DisclosureGroup {
                    ForEach(catg.appIds, id: \.self) { appId in
                        
                        if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
//                        LblExtractedSubview(matchedApp: matchedApp)
                            
                            Button {
                               if let idx = appSelected.firstIndex(of: appId) {
                                    appSelected.remove(at: idx)
                                    accumulatex -= 1
                                } else {
//                                if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
                                    withAnimation {
                                        accumulatex += 1
                                        appSelected.append(matchedApp.id)
                                        appCode = matchedApp.id
                                    }
                                }

                            } label: {
                                GroupBox {
                                     HStack {
                                         if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
                                             if appSelected.contains(matchedApp.id) {
                                                 Image(systemName: "checkmark.square")
                                                     .foregroundColor(.blue)
                                                     .scaleEffect(1.3)
                                             } else {
                                                 Image(systemName: "square")
                                                     .foregroundColor(.blue)                                             }
                                         }
                                         
                                         if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
                                             AsyncImage(url: URL(string: matchedApp.icon)) { image in
                                                 image.resizable()
                                             } placeholder: {
                                                 ProgressView()
                                             }
                                             .frame(width: 50, height: 50)
                                             .padding([.leading])
                                             
                                         } else {
                                             Text("the app Name is ")
                                         }
                                         
                                         
                                         if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
                                             Text(" \(matchedApp.name)") // assuming Appx has a property name
                                         } else {
                                             Text("the app Name is ")
                                         }
                                         
                                         Spacer()
                                     }.frame(maxWidth: .infinity)
                                }
                                .groupBoxStyle(CardGroupBoxStyle(bgclr: UIColor(ciColor: .init(red: catg.colorRGB.red, green: catg.colorRGB.green, blue: catg.colorRGB.blue, alpha: catg.colorRGB.alpha))))
                                .accentColor(Color.primary)
                                
                            }



                            /*
                           .onTapGesture {
                               
                               if let idx = passedItemSelected.firstIndex(of: itm.id) {
                                   passedItemSelected.remove(at: idx)
                                   
                               } else {
                                   passedItemSelected.append(itm.id)
                               }
                           }
        
                           .onTapGesture {
                               if (appSelected.firstIndex(where: { itm in
                                   itm == matchedApp.id
                               }) != nil)
                               appSelected.append(matchedApp.id)
                           }
 */
                            
                            
                            
                                //                        Text("the app Id is \(appId)")
                        }
                    }
                } label: {
                    Label {
                        Text(catg.title.capitalized)
                            
                    } icon: {
                        Image(systemName: catg.symbolName)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.init(red: catg.colorRGB.red, green: catg.colorRGB.green, blue: catg.colorRGB.blue, alpha: catg.colorRGB.alpha)))
//                    .background(Color.red)
                    .cornerRadius(10)
//                    .backgroundStyle(Color(.init(red: catg.colorRGB.red, green: catg.colorRGB.green, blue: catg.colorRGB.blue, alpha: catg.colorRGB.alpha)))
                }
                .padding()
                
            }.onAppear {
                print("ckckc")
            }
        }
            //        .task {
            //            do {
            //                print("in task")
            //                try await appxViewModel.loadData2()
            //                dump(appxViewModel.appx)
            //            } catch {
            //                print("error loading apps")
            //            }
            //
            //        }
        .onAppear {
            Task {
                do {
                    print("in task")
                    try await appxViewModel.loadData2()
                    dump(appxViewModel.appx)
                    print("in xxxx")
                } catch {
                    print("error loading apps")
                }
            }
            print("aaaa")
            dump(categoryViewModel.appCategories)
            dump(appxViewModel.appx)
        }
    }
    private func appPickerView() -> some View {
        Picker("Apps", selection: $selectedSegment) {
            ForEach(appSelected, id: \.self) { appsel in
                    //                        Text(appxViewModel.appx.filter { appSelected.contains($0.id) }[index].name).tag(index)
                if let idx = appxViewModel.appx.firstIndex(where: { $0.id == appsel }) {
                    HStack {
                        Text(appxViewModel.appx[idx].name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            //                                Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pickerStyle(.automatic)
    }
}


//struct CategoryDisclosureView_Previews: PreviewProvider {
//    var categoryViewModel = CategoryViewModel()
//
//    static var previews: some View {
//        CategoryDisclosureView().environmentObject(CategoryViewModel())
//    }
//}
