//
//  StudentTeacherListView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 4/29/23.
//

import SwiftUI

//struct StudentTeacherListView: View {
//    
//    @EnvironmentObject var usersViewModel: UsersViewModel
//    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
//    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
//
//    @Binding var selectedStudents: Array<Int>
//    @Binding var selectedTeachers: Array<Int>
//    
//    @Environment(\.presentationMode) var presentationMode
//    
//    var personType: PersonType
//    
//    var body: some View {
//        List {
//            Text(personType == PersonType.student ? "Select the students for this class" : "Select the teachers for this class" )
//                .foregroundColor(.blue)
//                .padding([.bottom])
//            
//            if personType == PersonType.student {
//                ForEach(usersViewModel.users.filter(
//                    { usr in
//                        !usr.groupIds.contains([appWorkViewModel.getTeacherGroup()])
//                    }).filter({ usr in
//                        usr.locationId ==  appWorkViewModel.currentLocation.id
//                    })
//                ) { student in
//                    HStack {
//                        Text("\(student.firstName) \(student.lastName)")
//                        Spacer()
//                        if selectedStudents.contains(student.id) {
//                            Image(systemName: "checkmark.square")
//                                .foregroundColor(.blue)
//                                .scaleEffect(1.3)
//                        } else {
//                            Image(systemName: "square")
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        
//                        if let idx = selectedStudents.firstIndex(of: student.id) {
//                            selectedStudents.remove(at: idx)
//                            
//                       } else {
//                            selectedStudents.append(student.id)
//                        }
//                    }
//                }
//            }
//            else {
//                ForEach(usersViewModel.users.filter({ usr in
//                    usr.groupIds.contains([appWorkViewModel.getTeacherGroup()])
//                }).filter({ usr in
//                    usr.locationId ==  appWorkViewModel.currentLocation.id
//                })
//                ) { teacher in
//                    HStack {
//                        Text("\(teacher.firstName) \(teacher.lastName)")
//                        Spacer()
//                        if selectedTeachers.contains(teacher.id) {
//                            Image(systemName: "checkmark.square")
//                                 .foregroundColor(.blue)
//                                 .scaleEffect(1.3)
//                         } else {
//                             Image(systemName: "square")
//                                 .foregroundColor(.blue)
//                         }
//
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        
//                        if let idx = selectedTeachers.firstIndex(of: teacher.id) {
//                            selectedTeachers.remove(at: idx)
//                            
//                       } else {
//                            selectedTeachers.append(teacher.id)
//                        }
//                    }
//                }
//            }
//        }
////        .listStyle(SidebarListStyle())
//        .navigationBarTitle("Select", displayMode: .inline)
//        .navigationBarItems(trailing: Button(action: {
//            presentationMode.wrappedValue.dismiss()
//        }) {
//            Text("Done")
//                .bold()
//        })
//    }
//    
//}
//
////struct StudentTeacherListView_Previews: PreviewProvider {
////    static var previews: some View {
////        StudentTeacherListView(selectedStudents: <#Binding<[Int]>#>, selectedTeachers: <#Binding<[Int]>#>, personType: <#PersonType#>)
////    }
////}
