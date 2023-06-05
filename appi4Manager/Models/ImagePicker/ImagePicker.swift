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
    
    @Published var imageSelection: PhotosPickerItem?   {
        didSet {
            if let imageSelection {
                Task {
                    try await loadTransferable2(from: imageSelection)
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
		 guard let studentId = self.studentId, let teachAuth = self.teachAuth else { 
			throw ImageProcessingError.missingInformation
		}
       
        guard let data = try await imageSelection?.loadTransferable(type: Data.self) else {
            throw ImageProcessingError.loadTransferablefailed
        }
        
        guard let uiImg = UIImage(data: data) else {
            throw ImageProcessingError.invalidImageData
        }

		// resize the image
        guard let resizedImageData = resizeImage(image: uiImg, toSizeInKB: 500),
              let resizedUIImage = UIImage(data: resizedImageData) else {
            throw ImageProcessingError.invalidResizedImageData
        }
        
        
        // take the UIImage and make it a SwiftUI Image
        image = Image(uiImage: resizedUIImage)
        
        // do api Update
        try await updatePhoto(id: studentId, teachAuth: teachAuth, data: resizedImageData)
        
    } catch let error as ImageProcessingError {
         print(error.errorDescription ?? "An error occurred")
        image = nil
    }
}


// resize the image
func resizeImage(image: UIImage, toSizeInKB maxSizeKB: Double) -> Data? {
	let maxSize = maxSizeKB * 1024.0
	var compression: CGFloat = 1.0
	var outputData: Data?

	repeat {
		compression *= 0.9
		outputData = image.jpegData(compressionQuality: compression)
	} while (outputData == nil || Double(outputData!.count) > maxSize) && compression > 0.1

	return outputData
}



// Using api Update Student Photo
func updatePhoto(id: Int, teachAuth: String, data: Data) async throws {
    do {
        let networkResponse: ApiManager.NetworkResponse = try await ApiManager.shared.getDataNoDecode(from: .updatePhoto(id: id, teachAuth: teachAuth, data: data))
        dump(networkResponse)
        // try classDetailViewModel.reloadData()
    } catch {
        print(error.localizedDescription)
    }
}
}
