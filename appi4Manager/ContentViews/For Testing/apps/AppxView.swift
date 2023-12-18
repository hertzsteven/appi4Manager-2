//
//  AppxView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/24/23.
//

import SwiftUI

struct AppxView: View {
    @EnvironmentObject var appxViewModel: AppxViewModel
    @State private var hasError = false
    @State private var error: ApiError?
    @State private var showApps: Bool = false
    
    
    var body: some View {
        ZStack {
            
            if appxViewModel.isLoading {
                VStack {
                    ProgressView().controlSize(.large).scaleEffect(2)
                }
            } else {
                
                Form {
                    Text("hello")
                    Button("get Apps") {
                        showApps = true
                    }
                }
            }
        }
        
//      MARK: -alerts  * * * * * * * * * * * * * * * * * * * * * * * *
        .alert(isPresented: $hasError,
               error: error) {
            Button {
                Task {
                    await loadTheapps()
                }
            } label: {
                Text("Retry")
            }
        }

//      MARK: -sheets  * * * * * * * * * * * * * * * * * * * * * * * *
               .sheet(isPresented: $showApps) {
                   ListTheApps(theApps: appxViewModel.appx)
               }

        
//      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
       .navigationTitle("apps")
       .navigationBarTitleDisplayMode(.inline)

//      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .task {
            if appxViewModel.ignoreLoading {
                appxViewModel.ignoreLoading = false
                    // Don't load the classes if ignoreLoading is true
            } else {
                    // Load the classes if ignoreLoading is false
                await loadTheapps()
                appxViewModel.ignoreLoading = false
            }
            
        }
    }

            
    func loadTheapps() async {
        do {
            try await appxViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
}


struct ListTheApps: View {
    let theApps: [Appx]
    var body: some View {
        List(theApps) { app in
             Text(app.name)
         }
    }
}

struct AppxView_Previews: PreviewProvider {
    static var previews: some View {
        AppxView()
    }
}
