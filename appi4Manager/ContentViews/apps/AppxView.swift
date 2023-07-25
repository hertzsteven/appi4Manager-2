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
    
    
    var body: some View {
        ZStack {
            
            if appxViewModel.isLoading {
                VStack {
                    ProgressView().controlSize(.large).scaleEffect(2)
                }
            } else {
                List(appxViewModel.appx) { app in
                    Text(app.name)
                }
            }
        }
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

struct AppxView_Previews: PreviewProvider {
    static var previews: some View {
        AppxView()
    }
}
