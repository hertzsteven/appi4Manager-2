//
//  testDEstFromClassView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/26/24.
//

import SwiftUI


struct DetailNavigationLink: View {
    var body: some View {
        NavigationLink("Go to Detail View", value: "Detail")
    }
}

struct TestDestFromClassView: View {
    // State variables to hold the text field inputs
    @State private var textField1: String = ""
    @State private var textField2: String = ""
    
    @State var mssg: String
    
    // NavigationPath instance to control the navigation programmatically
    @State private var navigationPath = NavigationPath()

    var body: some View {
//        NavigationStack(path: $navigationPath) {
            Form {
                Text("the number is  \(mssg)")
                TextField("Enter text here", text: $textField1)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                TextField("Enter more text", text: $textField2)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                // Use the extracted DetailNavigationLink view
                DetailNavigationLink()

                Spacer()
            }
//            .navigationTitle("Main View")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationDestination(for: String.self) { detailIdentifier in
//                // Detail view based on the navigation link's value
//                Text("Detail View for \(detailIdentifier)")
//            }
        }
//    }
}


//struct TestDestFromClassView: View {
//     State variables to hold the text field inputs
//    @State private var textField1: String = ""
//    @State private var textField2: String = ""
//    
//    @State var mssg: String
//    
//     NavigationPath instance to control the navigation programmatically
//    @State private var navigationPath = NavigationPath()
//    
//
//    var body: some View {
//        NavigationStack(path: $navigationPath) {
//            VStack {
//                Text(mssg)
//                TextField("Enter text here", text: $textField1)
//                    .textFieldStyle(.roundedBorder)
//                    .padding()
//                
//                TextField("Enter more text", text: $textField2)
//                    .textFieldStyle(.roundedBorder)
//                    .padding()
//
//                 Example navigation link to a detail view
//                NavigationLink("Go to Detail View", value: "Detail")
//
//                Spacer()
//            }
//            .navigationTitle("Main View")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationDestination(for: String.self) { detailIdentifier in
//                 Detail view based on the navigation link's value
//                Text("Detail View for \(detailIdentifier)")
//            }
//        }
//    }
//}

#Preview {
    TestDestFromClassView(mssg: "ieieiie")
}

