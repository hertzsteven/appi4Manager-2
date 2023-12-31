//
//  UserCardVwDup.swift
//  appi4Manager
//
//  Created by Steven Hertz on 4/18/23.
//

import SwiftUI

    //  MARK: -  What appears in the navigation link
struct UserCardVwDup: View {
    let user: User
    var urlPic: URL
    
    var body: some View {
        NavigationLink(value: user) {

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
                
                VStack(alignment: .center, spacing: 0) {
                    Text(user.firstName).lineLimit(1)
                    Text(user.lastName).lineLimit(1)
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
}

//struct UserCardVwDup_Previews: PreviewProvider {
//    static var previews: some View {
//        UserCardView()
//    }
//}
