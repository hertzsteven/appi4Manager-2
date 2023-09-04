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
    
    @Binding var apps: [Int]

    var body: some View {
        VStack(spacing: 32) {
            Button("dismiss") {
                presentMakeAppProfile.toggle()
            }
            Button("changeTo55") {
                sessionLength = Int.random(in: 901...999)
                print("changed session length to \(sessionLength)")
                let theAppcodes = [27,
                    17,
                    32,
                    11,
                    28]
                let filteredArray = theAppcodes.filter { theI in
                    !apps.contains(theI)
                }
                let theAppcode = filteredArray.randomElement()
                apps.removeAll()
                apps.append(theAppcode ?? 12121)
                print("changed aaps to \(apps)")
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
