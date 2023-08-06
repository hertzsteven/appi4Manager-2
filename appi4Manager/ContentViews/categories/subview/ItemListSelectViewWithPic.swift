//
//  ItemListSelectViewWithPic.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/26/23.
//

import SwiftUI


struct ItemListSelectViewWithPic<theItemsToSelect: ItemsToSelectRepresentablewithPic> : View {
    
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel

    @Binding var passedItemSelected: Array<Int>
    
    @Environment(\.presentationMode) var presentationMode
    
    var itemsToList: Array<theItemsToSelect>

    let itemFilter2: ((any ItemsToSelectRepresentablewithPic) -> Bool)?
    
    let listTitle: String
    
    var body: some View {
        List {
            Text(listTitle)
                .foregroundColor(.blue)
                .padding([.bottom])
            
            
            let itemFilter1: (theItemsToSelect) -> Bool = { item in
                item.locationId == appWorkViewModel.currentLocation.id
            }

            let filteredItems = itemsToList.filter(itemFilter1)
            
            let finalFilteredItems = itemFilter2.flatMap { filter in
                filteredItems.filter(filter)
            } ?? filteredItems

            
                ForEach(finalFilteredItems) { itm in
                    HStack {
                        Text("\(itm.nameToDisplay)")
                        Spacer()
                        
                        AsyncImage(url: URL(string: itm.icon)) { image in
                             image.resizable()
                         } placeholder: {
                             ProgressView()
                         }
                         .frame(width: 50, height: 50)
                         .padding([.leading])

                        
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

struct SampleItemwithPic: ItemsToSelectRepresentablewithPic {
    var id: Int
    var nameToDisplay: String
    var locationId: Int
    var icon: String
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
