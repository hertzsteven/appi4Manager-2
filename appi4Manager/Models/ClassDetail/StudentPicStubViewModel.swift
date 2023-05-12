//
//  StudentPicStubViewModel.swift
//  appi4Manager
//
//  Created by Steven Hertz on 4/23/23.
//

import SwiftUI
@MainActor
class StudentPicStubViewModel: ObservableObject {
    
//    static var uuid: String =  "abb340de-2faa-4dc8-bc9c-a53c0d31d51d"
    
    @Published var uuid: String = ""
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var students = [Student]()
    @Published var teachers = [Student]()
    
    @Published var isLoading = false
    
        //  FIXME:   Make this a throwing function
    func getURLpicForStudentWith(_ id: Int) -> URL {
        print("--- good in geturl student id \(id)")
        guard let idx = students.firstIndex(where: { student in
            student.id == id
        }) else {
            print("--- error in geturl student id \(id)")
            return URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!
        }
        return students[idx].photo
    }
    
    
//    init(uuid: String) {
//        Task {
//            do {
//                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: StudentPicStubViewModel.uuid))
//                self.students = classDetailResponse.class.students
//                self.name = classDetailResponse.class.name
//            } catch {
//                fatalError("lost")
//            }
//        }
//    }
    
    func  reloadData(uuid: String)  {
        guard !isLoading else { return }
        print("in it")
        isLoading = true
        
        Task {
            do {
                print("loading students")
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: uuid))
                self.students = classDetailResponse.class.students
                self.name = classDetailResponse.class.name
                dump(self.students)
                isLoading = false
            } catch {
                fatalError("lost")
            }
        }
    }
}
