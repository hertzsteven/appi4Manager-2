//
//  apps.swift
//  button Background
//
//  Created by Steven Hertz on 7/18/23.
//

import Foundation

struct Apps: Codable, Identifiable, Hashable, ItemsToSelectRepresentableStr {
    
    var id: String = UUID().uuidString
    var locationId: Int = Int.random(in: 0..<2)
    var title:      String
    var symbolName: String
    var nameToDisplay: String {
        title
    }
    
    static func == (lhs: Apps, rhs: Apps) -> Bool {
      return  lhs.title == rhs.title && lhs.symbolName == rhs.symbolName
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func getApps() -> Array<Apps> {
        let apps = [
            Apps(title: "Elmo Farm", symbolName: "airplane"),
            Apps(title: "Read It", symbolName: "car"),
            Apps(title: "Go Farm", symbolName: "radio"),
            Apps(title: "Match It", symbolName: "flag"),
            Apps(title: "What Color", symbolName: "bicycle"),
            Apps(title: "Moo", symbolName: "dice"),
        ]
        return apps
    }

}


class AppsViewModel: ObservableObject {
    
    private let userDefaultsKey = "apps1"
    
    @Published var apps = [Apps]() {
        didSet {
            if !apps.isEmpty {
                saveToUserDefaults()
            }
        }
    }
    
    
    init() {
//        apps = Apps.getApps()
        loadFromUserDefaults()
    }
    
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(apps) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadFromUserDefaults() {
        if let savedApps = UserDefaults.standard.object(forKey: userDefaultsKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedApps = try? decoder.decode([Apps].self, from: savedApps) {
                apps = loadedApps
            }
        }
    }
}
