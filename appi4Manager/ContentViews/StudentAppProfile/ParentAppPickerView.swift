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
    @State         var singleAppMode : Bool = false
    @State         var sessionLength : Int = 0
    @State var appCode = 0

    @State private var selectedSession: Session?
    
    var body: some View {
        VStack {
            Text("Main Screen")

            Button("Show Items") {
                isSheetPresented.toggle()
            }
            
            if let returnedSession = selectedSession,
                let theapp = returnedSession.apps.first {
                VStack {
                    Text("Selected session: \(theapp)")
                    Text("Length of time is: \(returnedSession.sessionLength)")
                    Text("one app lock is: \(returnedSession.oneAppLock ? "true" : "false" )")
                }
            }
        }
            
        .sheet(isPresented: $isSheetPresented) {
            CategoryDisclosureView(selectedSession: $selectedSession, isSheetPresented: $isSheetPresented, lengthOfSesssion: $sessionLength, singleAppMode: $singleAppMode, appCode: $appCode )
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
