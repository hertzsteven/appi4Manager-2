//
//  TestSchoolListView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/26/24.
//

import SwiftUI


struct TestSchoolListView : View {
    @EnvironmentObject var studentAppProfileManager: StudentAppProfileManager

    let nbrs = [1,2,3,4]
    var body: some View {
        ZStack {
             TestSchoolListViewBackgroundView(color: .orange, opacity: 0.3)
            Group {
                List(nbrs, id: \.self) { nbr in // Iterate over the nbrs array
//                    TestRow(nbr: nbr)
                    NavigationLink(value: nbr) {
                        TestRow(nbr: nbr)
                    }
//                    .navigationDestination(for: Int.self) { theNbr in
//                        if let studentFound = studentAppProfileManager.studentAppProfileFiles.first { $0.id == theNbr} {
//                                //                TestDestFromClassView(mssg: theNbr)
//                            StudentAppProfileWorkingView(
//                                studentId                   : theNbr,
//                                studentName                 : "Sam John",
//                                studentAppProfilefiles      : studentAppProfileManager.studentAppProfileFiles,
//                                profileManager: StudentAppProfileManager(),
//                                studentAppprofile           :  studentFound)
//                        }
//                    }
                    
                }
            }
            .navigationTitle("Main View To app profile")
            .navigationBarTitleDisplayMode(.inline)
            



            }
        
        
        .task {
            studentAppProfileManager.studentAppProfileFiles = await StudentAppProfileManager.loadProfilesx()
        }

        }
    }



struct  TestSchoolListViewBackgroundView: View {
    let color: Color
    let opacity: Double
    var body: some View {
        color
            .opacity(opacity)
            .ignoresSafeArea()
    }
}

struct  TestSchoolListViewForGroundView: View {
    let nbr: Int
    var body: some View {
        Text("the number is \(nbr)")
//        VStack {
//            Text("Hello,  world!")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .multilineTextAlignment(.center)
//                .minimumScaleFactor(0.1)
//        }
    }
}


struct TestRow : View  {
    let nbr: Int
    var body: some View {
        NavigationLink(value: nbr) {
            VStack(alignment: .leading, spacing: 6.0) {
                Text("the number is \(nbr)").font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}


#Preview {
    TestSchoolListView()
}
