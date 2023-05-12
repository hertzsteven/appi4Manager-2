//
//  UserCardView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 4/18/23.
//

import SwiftUI

    //  MARK: -  What appears in the navigation link
struct UserCardView: View {
    let user: User
    var urlPic: URL
    
    var body: some View {
        VStack {
            AsyncImage(url: urlPic) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Image("personPic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit() // Display the loaded image
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                        )

                case .failure:
                    Image("personPic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.red)
                        .tint(.red)

                @unknown default:
                    fatalError()
                }
            }
           // .frame(width: 100, height: 100)
//        }
//            Image("1")
//                .resizable()
//                .scaledToFit()
//                .clipShape(Circle())
//                .frame(width: 100, height: 100)
//                .overlay(
//                    Circle()
//                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
//                )
            VStack(alignment: .center, spacing: 0) {
                Text(user.firstName)
                Text(user.lastName)
            }
            .frame(width: 90)
            .font(.body)
            
        } // end of VStack which is the label of Navigation Link
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 10, x: 4, y: 4)
    }
}

//struct UserCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserCardView()
//    }
//}
