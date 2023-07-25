    //
    //  Components.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 7/25/23.
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
