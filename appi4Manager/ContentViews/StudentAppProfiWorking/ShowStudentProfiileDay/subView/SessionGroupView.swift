//
//  SessionGroupView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/28/23.
//

import SwiftUI


struct SessionGroupView: View {
    @EnvironmentObject  var appxViewModel:  AppxViewModel
    @State private var isEditing = false
    @State   var selectedNum: Double = 0.0
    
    let timeOfDay:                      LocalizedStringKey
    @Binding var sessionLength:         Int {
        didSet {
            selectedNum = Double(sessionLength)
        }
    }

    @Binding var iPadLockedIntoApp:     Bool
    let seesionNumber:                  Int
    @Binding var appList:               String
    @Binding var isSheetPresented:      Bool
    @Binding var appCodeAM:             Int
    @Binding var sessionLengthDoubleAM: Double
    
    var body: some View {
        Group {
            HStack {
                Text(timeOfDay)
                    .padding([ .leading])
                Spacer()
                Button("Set Student App ") {
                    isSheetPresented.toggle()
                }.padding(.trailing)
            }
            VStack(alignment: .leading, spacing: 4) {
//                Text("**appCode:** \(appCodeAM) ")
                HStack {
                    Text("Minutes: \(sessionLengthDoubleAM, specifier: "%.f")   ")
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
                Toggle(isOn: $iPadLockedIntoApp, label: {
                    Text("Locked INto the App").font(.headline)
                }).disabled(true)
                
                Text("**Session Length:** \(sessionLength) minutes")
                Text("**iPad Locked to app:** \( iPadLockedIntoApp ? "Locked" : "Not Locked")")
                Divider()
                VStack {
                    Label {
                        if let appName = getAppNameWithId(appCodeAM) {
                            Text("\(appName)")
                        } else {
                            Text("eiodjijf3pihf3ifh3ofhi3ofihi3foih")
                        }
                    } icon: {
                        if let app = getAppWithId(appCodeAM) {
                            AsyncImage(url: URL(string: app.icon)) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 48, height: 48)

//                            Image("Dkdkdk")
//                                .resizable()
//                                .frame(width: 48, height: 48, alignment: .leading)
                        }
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
        .onAppear {
           
        }
    }

    func getAppNameWithId(_ appId: Int?) -> String? {
         guard let appId = appId else {return nil}
         do {
             let app = try appxViewModel.getAppWith(appId)
             return app.name
             // Use the app here
         } catch AppError.appNotFound {
             print("App with the given ID was not found.")
             return nil
         } catch {
             print("An unknown error occurred.")
             return nil
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
