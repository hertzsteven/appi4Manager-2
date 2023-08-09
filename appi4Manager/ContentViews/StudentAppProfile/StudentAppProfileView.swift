    //
    //  StudentAppProfileView2.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 8/8/23.
    //

import SwiftUI

struct StudentAppProfileView: View {
    
    init() {
        viewModel = StudentAppProfileViewModel()
        if viewModel.profiles.isEmpty {
            viewModel.profiles.append(contentsOf: StudentAppProfileViewModel.loadProfiles())
        }
    }
    
    @ObservedObject var viewModel: StudentAppProfileViewModel
    @State private var currentProfile: StudentAppProfile? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Load Samples") {
                    print("Load Samples")
                }
                
                List {
                    ForEach (viewModel.profiles) { profile in
                        Text("Student Id \(profile.id)")
                            .onTapGesture {
                                currentProfile = profile
                            }
                    }
                }
            }
            .navigationBarTitle("Profiles")
            .navigationBarItems(trailing: Button("Add") {
//                currentProfile = StudentAppProfileViewModel.sampleProfile()
            })
            .sheet(item: $currentProfile) { profile in
                ProfileDetail(profile: profile, saveAction: { updatedProfile in
                    if let index = viewModel.profiles.firstIndex(where: { $0.id == updatedProfile.id }) {
                        viewModel.profiles[index] = updatedProfile
                    } else {
                        viewModel.addProfile(profile: updatedProfile)
                    }
                    viewModel.saveProfiles()
                })
            }
        }
    }
    func deleteProfile(at offsets: IndexSet) {
        viewModel.profiles.remove(atOffsets: offsets)
        viewModel.saveProfiles()
    }
}


struct StudentAppProfileView2_Previews: PreviewProvider {
    static var previews: some View {
        StudentAppProfileView()
    }
}


struct ProfileDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @State var profile: StudentAppProfile
    var saveAction: ((StudentAppProfile) -> Void)?

    var body: some View {
        
        Text("dldlldl")

        .navigationBarItems(trailing: Button("Save") {
            saveAction?(profile)
            presentationMode.wrappedValue.dismiss()
        })
    }
}
