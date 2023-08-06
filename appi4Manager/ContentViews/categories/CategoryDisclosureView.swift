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

struct CategoryDisclosureView: View {
    @EnvironmentObject var appxViewModel :    AppxViewModel
    @EnvironmentObject var appWorkViewModel : AppWorkViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    
    var appSelected: Array<Int> = []
    
    @State var accumulatex: Double = 0

    
    var body: some View {
        
        if accumulatex > 0 {
            GroupBox {
                Text("Hello how are you")
                    .frame(maxWidth: .infinity)
                    .padding()
                
                Button("reset") {
                    withAnimation {
                        accumulatex = 0
                    }
                    
                }
            }
            .padding()
            .cornerRadius(12.0, antialiased: true)
            .opacity(accumulatex > 0 ? 1 : 0)
            .animation(Animation.easeInOut(duration: 2.0), value: accumulatex)
            
        }
        
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(categoryViewModel.filterCategoriesinLocation(appWorkViewModel.currentLocation.id)) { catg in
                DisclosureGroup {
                    ForEach(catg.appIds, id: \.self) { appId in
                        
                        if let matchedApp = appxViewModel.appx.first(where: { $0.id == appId }) {
//                        LblExtractedSubview(matchedApp: matchedApp)
                           GroupBox {
                                HStack {
                                    Image(systemName: "checkmark.square")
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
}


struct CategoryDisclosureView_Previews: PreviewProvider {
    var categoryViewModel = CategoryViewModel()
    
    static var previews: some View {
        CategoryDisclosureView().environmentObject(CategoryViewModel())
    }
}
