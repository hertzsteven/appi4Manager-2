//
//  TestMVVMView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/22/24.
//

import SwiftUI

struct TestMVVMView: View {
    @ObservedObject var viewModel: StudentAppProfileFS
    
    init(studentId: Int, locationID: Int) {
        self.viewModel = StudentAppProfileFS(id: studentId, locationId: locationID)
    }
    @State var appCount: Int = 0
    
    var body: some View {
        Text("Hello, World!")
        Text("\(viewModel.appCount)")
        Button {
            print("hello")
        } label: {
            Text("Make student app profile")
        }
    }
}

//#Preview {
//    TestMVVMView()
//}
