//
//  ParentAppPickerView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/13/23.
//

import SwiftUI

struct Person {
    let name: String
    let age: Int
}

struct ParentAppPickerView: View {
    @State private var isSheetPresented = false
    @State private var selectedPerson: Person?
    
    @State private var selectedSession: Session?
    
    var body: some View {
        VStack {
            Text("Main Screen")

            Button("Show Items") {
                isSheetPresented.toggle()
            }
            
            if let session = selectedSession, let theapp = session.apps.first {
                Text("Selected session: \(theapp)")
            }
        }
        

        
//        .sheet(isPresented: $isSheetPresented) {
//            PersonListView(selectedPerson: $selectedPerson, isSheetPresented: $isSheetPresented)
//        }
        
        .sheet(isPresented: $isSheetPresented) {
            CategoryDisclosureView(selectedSession: $selectedSession, isSheetPresented: $isSheetPresented)
        }

    }
    var myItem: some View {
        Text("Main Screen")
    }
}

struct PersonListView: View {
    @Binding var selectedPerson: Person?
    @Binding var isSheetPresented: Bool
    
    let people = [
        Person(name: "John", age: 25),
        Person(name: "Jane", age: 30),
        Person(name: "Bob", age: 22)
    ]
    
    var body: some View {
        NavigationView {
            List(people, id: \.name) { person in
                Button(action: {
                    selectedPerson = person
                    isSheetPresented = false
                }) {
                    Text("\(person.name), Age: \(person.age)")
                }
            }
            .navigationTitle("Select a Person")
        }
    }
}
struct ParentAppPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ParentAppPickerView()
    }
}
