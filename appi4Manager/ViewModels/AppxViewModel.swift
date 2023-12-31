//
//  AppxViewModel.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/24/23.
//

import SwiftUI

enum AppError: Error {
    case appNotFound
}


@MainActor
class AppxViewModel: ObservableObject {

    @Published var appx = [Appx]() {
        didSet {
            if !appx.isEmpty {
                saveToUserDefaults()
                isLoaded = true
            }
        }
    }

    @Published var isLoading        = false
    @Published var ignoreLoading    = false
    @Published var isLoaded         = false

    
    private let userDefaultsKey = "apps1"

    init(appx: [Appx] = []) {
         self.appx = appx
     }

    
    init() {
//        apps = Apps.getApps()
//        loadFromUserDefaults()
    }
    
    
    func loadData2() async throws {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
//        try await Task.sleep(nanoseconds: 3 * 1_000_000_000) // 1 second = 1_000_000_000 nanoseconds

        let resposnse: AppResponse = try await ApiManager.shared.getData(from: .getApps)
        print("after getting apps")
        DispatchQueue.main.async {
            print("doing the dispatchque")
            self.appx = resposnse.apps
            self.isLoaded = true
            
        }
    }
    
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(appx) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadFromUserDefaults() {
        if let savedApps = UserDefaults.standard.object(forKey: userDefaultsKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedApps = try? decoder.decode([Appx].self, from: savedApps) {
                appx = loadedApps
            }
        }
    }
    func getAppWith(_ appId: Int) throws -> Appx {
        if let app = self.appx.first(where: { $0.id == appId }) {
            return app
        } else {
            throw AppError.appNotFound
        }
    }

}
