    //
    //  NavigateToStudentAppProfile.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 8/10/23.
    //

import SwiftUI

struct NavigateToStudentAppProfile: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Hello World!")

            NavigationLink("go there", value: StudentAppProfile(id: 0, locationId: 0,
                                                                sessions: ["xx": DailySessions(
                                                                    amSession: Session(apps: [0], sessionLength: 0, oneAppLock: false),
                                                                    pmSession: Session(apps: [0], sessionLength: 0, oneAppLock: false),
                                                                    homeSession: Session(apps: [0], sessionLength: 0, oneAppLock: false))]
                                                               )
            )
        }
        
        .navigationTitle("launch profile")
        
        .navigationDestination(for: StudentAppProfile.self, destination: {prf  in
            
            let studentProfiles = StudentAppProfileViewModel.loadProfiles()
            
            if let idx = studentProfiles.firstIndex(where: { prf in
                prf.id == 8
            }) {
                AppProfileWeeklyView(currentProfile: studentProfiles[idx])
            } else {
                AppProfileWeeklyView(currentProfile: prf)
            }
            
        })
    }
}

struct NavigateToStudentAppProfile_Previews: PreviewProvider {
    static var previews: some View {
        NavigateToStudentAppProfile()
    }
}

