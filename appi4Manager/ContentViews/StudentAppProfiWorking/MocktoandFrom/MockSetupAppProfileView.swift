//
//  MockSetupAppProfile.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/31/23.
//

import SwiftUI

struct MockSetupAppProfileView: View {

    @Binding var presentMakeAppProfile: Bool
    
    let selectedDay: DayOfWeek
    
    @Binding var sessionLength: Int

    var body: some View {
        VStack(spacing: 32) {
            Button("dismiss") {
                presentMakeAppProfile.toggle()
            }
            Button("changeTo55") {
                sessionLength = 55
                presentMakeAppProfile.toggle()
            }

            Text(selectedDay.asAString )
        }
        .padding()
    }
}

//struct MockSetupAppProfile_Previews: PreviewProvider {
//    static var previews: some View {
//        MockSetupAppProfileView()
//    }
//}
