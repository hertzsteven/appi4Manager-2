//
//  ItemListSelectView.swift
//  button Background
//
//  Created by Steven Hertz on 7/18/23.
//

import SwiftUI


//// fix make apps conform and change id type
//protocol ItemsToSelectRepresentableStr: Identifiable {
//    var locationId: Int { get }
//    var nameToDisplay: String { get }
//    var id: String { get }
//    var symbolName: String {get}
//}



struct ItemListSelectViewStr<theItemsToSelect: ItemsToSelectRepresentableStr> : View {
    
// fix
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel

    @Binding var passedItemSelected: Array<String>
    
    @Environment(\.presentationMode) var presentationMode
    
    var itemsToList: Array<theItemsToSelect>

    let itemFilter2: ((any ItemsToSelectRepresentableStr) -> Bool)?
    
    let listTitle: String
    
    var body: some View {
        List {
            Text(listTitle)
                .foregroundColor(.blue)
                .padding([.bottom])
            
// fix
            let itemFilter1: (theItemsToSelect) -> Bool = { item in
//                item.locationId == appWorkViewModel.currentLocation.id
                item.locationId == 1

            }

            let filteredItems = itemsToList.filter(itemFilter1)
            
            let finalFilteredItems = itemFilter2.flatMap { filter in
                filteredItems.filter(filter)
            } ?? filteredItems

            
                ForEach(finalFilteredItems) { itm in
                    HStack {
                        Label("\(itm.nameToDisplay)", systemImage: itm.symbolName)
//                        Text("\(itm.nameToDisplay)")
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
//
//struct SampleItem: ItemsToSelectRepresentableStr {
//    var id: String
//    var nameToDisplay: String
//    var locationId: Int
//    var symbolName: String
//
//}
//
//struct ItemListSelectView_Previews: PreviewProvider {
//    @State static var selectedItemIds: [String] = []
//
//    static var sampleItems: [SampleItem] = [
//        SampleItem(id: "1", nameToDisplay: "Item 1", locationId: 0, symbolName: "pen"),
//        SampleItem(id: "2", nameToDisplay: "Item 2", locationId: 0, symbolName: "pen"),
//        SampleItem(id: "3", nameToDisplay: "Item 3", locationId: 1, symbolName: "pen"),
//        SampleItem(id: "4", nameToDisplay: "Item 4", locationId: 1, symbolName: "pen")
//    ]
//
//    static var previews: some View {
//        ItemListSelectViewStr(passedItemSelected: $selectedItemIds, itemsToList: sampleItems, itemFilter2: nil, listTitle: "Sample Items")
//            .environmentObject(AppWorkViewModel())
//    }
//}
//
