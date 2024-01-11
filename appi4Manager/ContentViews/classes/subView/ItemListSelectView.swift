//
//  ItemListSelectView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 4/30/23.
//

import SwiftUI

struct ItemListSelectView<theItemsToSelect: ItemsToSelectRepresentable> : View {
    
    @EnvironmentObject var teacherItems: TeacherItems
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel

    @Binding var passedItemSelected: Array<Int>
    
    @Environment(\.presentationMode) var presentationMode
    
    var itemsToList: Array<theItemsToSelect>

    let itemFilter2: ((any ItemsToSelectRepresentable) -> Bool)?
    
    let listTitle: String
    
    var body: some View {
        List {
            Text(listTitle)
                .foregroundColor(.blue)
                .padding([.bottom])
            
            
            let itemFilter1: (theItemsToSelect) -> Bool = { item in
                item.locationId == teacherItems.currentLocation.id
            }

            let filteredItems = itemsToList.filter(itemFilter1)
            
            let finalFilteredItems = itemFilter2.flatMap { filter in
                filteredItems.filter(filter)
            } ?? filteredItems

            
                ForEach(finalFilteredItems) { itm in
                    HStack {
                        Text("\(itm.nameToDisplay)")
                        Spacer()
                        
                        if passedItemSelected.contains(itm.id) {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(.blue)
                                .scaleEffect(1.3)
                        } else {
                            Image(systemName: "square")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        
                        if let idx = passedItemSelected.firstIndex(of: itm.id) {
                            passedItemSelected.remove(at: idx)
                            
                        } else {
                            passedItemSelected.append(itm.id)
                        }
                    }
                }
        }
            //        .listStyle(SidebarListStyle())
        .navigationBarTitle("Select", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Done")
                .bold()
        })
    }
}

struct ItemListSelectViewDVC: View {
    
    @EnvironmentObject var teacherItems: TeacherItems

    @Binding var passedItemSelected: Array<TheDevice>
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var itemsToList: Array<TheDevice>

//    let itemFilter2: ((any ItemsToSelectRepresentable) -> Bool)?
    
    let listTitle: String
    
    var body: some View {
        List {
            Text(listTitle)
                .foregroundColor(.blue)
                .padding([.bottom])
            
            
//            let itemFilter1: (theItemsToSelect) -> Bool = { item in
//                item.locationId == teacherItems.currentLocation.id
//            }
//
//            let filteredItems = itemsToList.filter(itemFilter1)
            
//            let finalFilteredItems = itemFilter2.flatMap { filter in
//                filteredItems.filter(filter)
//            } ?? filteredItems

            
            ForEach(itemsToList) { itm in
                HStack {
                    Text(itm.name)
                    Spacer()
                    if passedItemSelected.contains(where: { $0.id == itm.id }) {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.blue)
                            .scaleEffect(1.3)
                    } else {
                        Image(systemName: "square")
                            .foregroundColor(.blue)
                    }

                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let idx = passedItemSelected.firstIndex(where: { $0.id == itm.id }) {
                        print("dd")
                        passedItemSelected.remove(at: idx)
                    } else {
                        passedItemSelected.append(itm)
                    }
                }
            
//                ForEach(itemsToList) { itm in
//                    HStack {
//                        Text("sksks")
//                        Spacer()
//                        
//                        if passedItemSelected.contains(where: itm.id) {
//                            Image(systemName: "checkmark.square")
//                                .foregroundColor(.blue)
//                                .scaleEffect(1.3)
//                        } else {
//                            Image(systemName: "square")
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        
//                        if let idx = passedItemSelected.firstIndex(of: itm.id) {
//                            passedItemSelected.remove(at: idx)
//                            
//                        } else {
//                            passedItemSelected.append(itm)
//                        }
//                    }
                }
        }
            //        .listStyle(SidebarListStyle())
        .navigationBarTitle("Select", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Done")
                .bold()
        })
    }
}
struct SampleItem: ItemsToSelectRepresentable {
    var id: Int
    var nameToDisplay: String
    var locationId: Int
}

//struct ItemListSelectView_Previews: PreviewProvider {
//    @State static var selectedItemIds: [Int] = []
//
//    static var sampleItems: [SampleItem] = [
//        SampleItem(id: 1, nameToDisplay: "Item 1", locationId: 0),
//        SampleItem(id: 2, nameToDisplay: "Item 2", locationId: 0),
//        SampleItem(id: 3, nameToDisplay: "Item 3", locationId: 1),
//        SampleItem(id: 4, nameToDisplay: "Item 4", locationId: 1)
//    ]
//
//    static var previews: some View {
//        ItemListSelectView(passedItemSelected: $selectedItemIds, itemsToList: sampleItems, itemFilter2: nil, listTitle: "Sample Items")
//            .environmentObject(AppWorkViewModel())
//    }
//}
