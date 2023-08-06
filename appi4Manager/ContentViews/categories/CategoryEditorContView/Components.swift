    //
    //  Components.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 7/25/23.
    //

import SwiftUI

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
    @EnvironmentObject var model:           CategoryViewModel
    @EnvironmentObject var appxViewModel:   AppxViewModel
    @Environment(\.editMode) var editMode
    
    @Binding var isListVisible: Bool
    @Binding var newItem:       String
    @Binding var listData:      [Int]
    let title:      String
    let appArray: [Appx]
    
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
                Label {
                    Text("\(app.nameToDisplay)")
                } icon: {
                    AsyncImage(url: URL(string: app.icon)) { image in
                         image.resizable()
                     } placeholder: {
                         ProgressView()
                     }
                     .frame(width: 32, height: 32)
//                     .padding([.leading])
                }

              //  Label("\(app.nameToDisplay)", systemImage: "pencil")
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
