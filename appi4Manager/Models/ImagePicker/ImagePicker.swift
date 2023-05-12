//
//  ImagePicker.swift
//  list the users
//
//  Created by Steven Hertz on 4/3/23.
//

import SwiftUI
import PhotosUI

@MainActor
class ImagePicker: ObservableObject {
    
    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    
    @Published var image: Image?
    @Published var images: [Image] = []
    
    @Published var imageSelection: PhotosPickerItem? {
        didSet {
            if let imageSelection {
                Task {
                    try await loadTransferable(from: imageSelection)
                }
            }
        }
    }
    
    @Published var imageSelections: [PhotosPickerItem] = [] {
        didSet {
            Task {
                if !imageSelections.isEmpty {
                    try await loadTransferable(from: imageSelections)
                    imageSelections = []
                }
            }
        }
    }
    
    //  MARK: -  required for updating student photo    
    @Published var studentId: Int?
    @Published var teachAuth: String?
    
    
    func loadTransferable(from imageSelection: PhotosPickerItem?) async throws {
            //        print(Image.transferRepresentation)
        guard let studentId = self.studentId, let teachAuth = self.teachAuth else { fatalError("Missing Infor,ation") }
        
        do {
            if let data = try await imageSelection?.loadTransferable(type: Data.self) {
                
                guard let uiImg = UIImage(data: data) else {fatalError("ddddd")}
                image = Image(uiImage: uiImg)
                print("the student id is \(studentId)")
                Task {
                    do {
                        let networkResponse: ApiManager.NetworkResponse = try await ApiManager.shared.getDataNoDecode(from: .updatePhoto(id: studentId, teachAuth: teachAuth, data: data) )
                        dump(networkResponse)
                       // try classDetailViewModel.reloadData()
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                }

                
                
//                let x = UploadPhoto()
//                x.fileData = data
//                Task {
//                    await x.sendRequest()
//                }
//                if let uiImage = UIImage(data: data) {
//                    self.image = Image(uiImage: uiImage)
//                }
            }
        } catch {
            print(error.localizedDescription)
            image = nil
        }
    }
    
    func loadTransferable(from imageSelections: [PhotosPickerItem]) async throws {
        do {
            for imageSelection in imageSelections {
                if let data = try await imageSelection.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        self.images.append(Image(uiImage: uiImage))
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    

    // TODO: It does not work for most of the types
    func loadTransferable2(from imageSelection: PhotosPickerItem?) async throws {
         do {
            if let image = try await imageSelection?.loadTransferable(type: Image.self) {
                self.image = image
            }
        } catch {
            print(error.localizedDescription)
            image = nil
        }
    }
}
