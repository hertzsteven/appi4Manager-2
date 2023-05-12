//
//  StubStartView.swift
//  list the users
//
//  Created by Steven Hertz on 3/26/23.
//

import SwiftUI

struct StubStartView: View {
    var body: some View {
        NavigationView {
            NavigationLink("Go") {
                UserListContent(newUser:  User.makeDefault())
            }
        }

        
    }
}

struct StubStartView_Previews: PreviewProvider {
    static var previews: some View {
        StubStartView()
    }
}
