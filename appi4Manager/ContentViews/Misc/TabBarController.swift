  //
  //  TabBarController.swift
  //  list the users
  //
  //  Created by Steven Hertz on 2/8/23.
  //

import SwiftUI

struct TabBarController : View {
  
  @EnvironmentObject var appWorkViewModel: AppWorkViewModel

  
  var body: some View {
    TabView {
        //            NavigationView {
      UserListContent(newUser: User.makeDefault())
        //            }
        .tabItem {
          Label("students", systemImage: "person")
            //                    Image(systemName: "person")
            //                    Text("Students")
        }
      
        SchoolListContent(path: .constant(NavigationPath()), newClass: SchoolClass.makeDefault())
        //                .toolbar(.visible, for: .tabBar)
        .tabItem {
            Image(systemName: "person.2.square.stack")
            Text("Classes")
        }
    }
  }
}


struct TabBarController_Previews: PreviewProvider {
  static var previews: some View {
    TabBarController()
  }
}
