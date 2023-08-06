//
//  AppCategory.swift
//  button Background
//
//  Created by Steven Hertz on 6/14/23.
//

import SwiftUI
import Foundation

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}

struct ColorRGB: Codable, Equatable, Hashable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
}


struct AppCategory: Codable, Identifiable, Hashable {
    static func == (lhs: AppCategory, rhs: AppCategory) -> Bool {
      return  lhs.title == rhs.title && lhs.symbolName == rhs.symbolName && lhs.colorRGB == rhs.colorRGB
    }
    
    
    var id: String = UUID().uuidString
    var title:      String
    var symbolName: String
    var colorRGB:   ColorRGB
    var appIds:     [Int] = []
    var locationId:  Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

extension AppCategory {
    static func makeDefault() -> AppCategory {
        let uiColor = UIColor(CategoryColors.random())
        let rgba = uiColor.rgba
        return AppCategory(title: "",
                           symbolName: CategorySymbols.randomName(),
                           colorRGB: ColorRGB(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha),
                           appIds: [1], locationId:0
        )
    }
}


class CategoryViewModel: ObservableObject {
    @Published var appCategories = [AppCategory]() {
        didSet {
            if !appCategories.isEmpty {
                saveToUserDefaults()
            }
        }
    }

    private let userDefaultsKey = "appCategories7"
    init() {
//        loadSomeSamples()
        loadFromUserDefaults()
    }


    func filterCategoriesinLocation(_ locationId: Int) -> Array<AppCategory> {
        var filteredCategoriesbyLocation = [AppCategory]()
        
        filteredCategoriesbyLocation = appCategories.filter{ appCategory in
            appCategory.locationId  == locationId
        }
        
        return filteredCategoriesbyLocation
    }
  
//    func getCategoriesByLocation(location: Int) -> Array<AppCategory> {
//        appCategories.filter { appCtg in
//            appCtg.
//        }
//    }
    
    func loadSomeSamples()  {
        let ar = [
            AppCategory(title: "the first one", symbolName: "star", colorRGB: ColorRGB(red: 0.3, green: 0.7, blue: 0.1, alpha: 1), locationId: 0),
            AppCategory(title: "the second one", symbolName: "star", colorRGB: ColorRGB(red: 0.6, green: 0.3, blue: 0.4, alpha: 1), locationId: 0),
            AppCategory(title: "the third one", symbolName: "star", colorRGB: ColorRGB(red: 0.8, green: 0.9, blue: 0.7, alpha: 1), locationId: 1),
            ]
    
        appCategories.append(contentsOf: ar)
    }

    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(appCategories) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadFromUserDefaults() {
        if let savedAppCategories = UserDefaults.standard.object(forKey: userDefaultsKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedAppCategories = try? decoder.decode([AppCategory].self, from: savedAppCategories) {
                appCategories = loadedAppCategories
            }
        }
    }
}


