//
//  ApiHelper.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation


class APISchoolInfo {
    // Non-optional properties
    let companyUrl:    String
    let apiKey:        String
    let asset:         String
    let udid:          String
    let companyId:     Int
    let helpurl:       String
    
    // Version and config source tracking
    let appVersion:    String = "1.0.1"
    let configSource:  SourceOfNetworkProperties

    // MARK: - Environment Variable Keys (for local development)
    private enum EnvKey {
        static let apiURL     = "API_URL"
        static let apiKey     = "API_KEY"
        static let companyId  = "COMPANY_ID"
        static let asset      = "ASSET"
        static let udid       = "UDID"
        static let helpURL    = "HELP_URL"
    }
    
    // Singleton instance
    static let shared: APISchoolInfo = {
        // First try MDM (production)
        if let networkVariables = getValuesFromManagedConfigFile() {
            #if DEBUG
            print("⚙️ ========================================")
            print("⚙️ MDM CONFIG: Successfully loaded from MDM! ✅")
            print("⚙️ Source: \(networkVariables.sourceOfNetworkProperties)")
            print("⚙️ URL: \(networkVariables.companyUrl)")
            print("⚙️ CompanyId: \(networkVariables.CompanyId)")
            print("⚙️ Asset: \(networkVariables.asset)")
            print("⚙️ UDID: \(networkVariables.udid)")
            print("⚙️ Help URL: \(networkVariables.helpurl)")
            print("⚙️ ========================================")
            #endif
            return APISchoolInfo(urlEndPoint:   networkVariables.companyUrl,
                                 apiKey:        networkVariables.apiKey,
                                 asset:         networkVariables.asset,
                                 udid:          networkVariables.udid,
                                 companyId:     networkVariables.CompanyId,
                                 helpurl:       networkVariables.helpurl,
                                 configSource:  .mdm)
        }
        
        // Debug builds: use environment variables from Xcode scheme
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let apiUrl = env[EnvKey.apiURL],
           let apiKey = env[EnvKey.apiKey],
           let companyIdStr = env[EnvKey.companyId],
           let companyId = Int(companyIdStr) {
            print("⚙️ ========================================")
            print("⚙️ MDM CONFIG: Using ENVIRONMENT VARIABLES (dev)")
            print("⚙️ URL: \(apiUrl)")
            print("⚙️ CompanyId: \(companyId)")
            print("⚙️ ========================================")
            return APISchoolInfo(urlEndPoint:   apiUrl,
                                 apiKey:        apiKey,
                                 asset:         env[EnvKey.asset] ?? "asset",
                                 udid:          env[EnvKey.udid] ?? "udid",
                                 companyId:     companyId,
                                 helpurl:       env[EnvKey.helpURL] ?? "www.help.com",
                                 configSource:  .fallback)
        }
        #endif
        
        fatalError("No configuration available. Set environment variables in Xcode scheme (API_URL, API_KEY, COMPANY_ID) or deploy via MDM.")
    }()

    // Private initializer
    private init(urlEndPoint:   String,
                 apiKey:        String,
                 asset:         String,
                 udid:          String,
                 companyId:     Int,
                 helpurl:       String,
                 configSource:  SourceOfNetworkProperties) {
        self.companyUrl   = urlEndPoint
        self.apiKey       = apiKey
        self.asset        = asset
        self.udid         = udid
        self.companyId    = companyId
        self.helpurl      = helpurl
        self.configSource = configSource
    }

    static private func getValuesFromManagedConfigFile() -> NetworkConnectionVariables? {
        
        #if DEBUG
        print("⚙️ MDM CONFIG: Attempting to load from '\(AppConfigKeys.fileName)'...")
        #endif

        guard let managedConfigObj = UserDefaults.standard.object(forKey: AppConfigKeys.fileName ) else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - No MDM configuration file found")
            print("⚙️ MDM CONFIG: Key '\(AppConfigKeys.fileName)' not present in UserDefaults")
            #endif
            return nil
        }
        
        #if DEBUG
        print("⚙️ MDM CONFIG: ✅ Found MDM configuration object")
        #endif
          
        guard let managedConfigDict = managedConfigObj as? [String:Any?] else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Could not cast config to [String:Any?]")
            #endif
            return nil
        }
        
        #if DEBUG
        print("⚙️ MDM CONFIG: ✅ Successfully cast to dictionary")
        print("⚙️ MDM CONFIG: Available keys: \(managedConfigDict.keys.joined(separator: ", "))")
        #endif

        guard let thecompanyUrl = managedConfigDict[AppConfigKeys.companyUrl] as? String else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.companyUrl)'")
            #endif
            return nil
        }
        
        guard let theapi = managedConfigDict[AppConfigKeys.api] as? String else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.api)'")
            #endif
            return nil
        }
        
        guard let theasset = managedConfigDict[AppConfigKeys.asset] as? String else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.asset)'")
            #endif
            return nil
        }
        
        guard let theudid = managedConfigDict[AppConfigKeys.udid] as? String else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.udid)'")
            #endif
            return nil
        }
        
        guard let theCompanyId = managedConfigDict[AppConfigKeys.companyId] as? Int else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.companyId)'")
            #endif
            return nil
        }
        
        guard let thehelpurl = managedConfigDict[AppConfigKeys.helpurl] as? String else {
            #if DEBUG
            print("⚙️ MDM CONFIG: ❌ FAILED - Missing or invalid key '\(AppConfigKeys.helpurl)'")
            #endif
            return nil
        }
        
        #if DEBUG
        print("⚙️ MDM CONFIG: ✅ All required keys found and valid")
        #endif
          
        let networkConnectionVariables = NetworkConnectionVariables(companyUrl               : thecompanyUrl,
                                                                    apiKey                   : theapi,
                                                                    asset                    : theasset,
                                                                    udid                     : theudid,
                                                                    CompanyId                : theCompanyId,
                                                                    helpurl                  : thehelpurl,
                                                                    sourceOfNetworkProperties: .mdm)
          
        return networkConnectionVariables
    }

}

// Define other necessary structs and enums as before

struct NetworkConnectionVariables {
    var companyUrl: String
    var apiKey: String
    var asset: String
    var udid: String
    var CompanyId: Int
    var helpurl: String
    var sourceOfNetworkProperties: SourceOfNetworkProperties
}


enum AppConfigKeys {
    static var fileName     = "com.apple.configuration.managed"
    static var companyUrl   = "companyUrl"
    static var api          = "apiKey"
    static var asset        = "asset"
    static var udid         = "udid"
    static var companyId    = "companyId"
    static var helpurl      = "helpurl"
}


enum SourceOfNetworkProperties {
    case mdm, userDefaults, fireStore, fallback
    
    var displayName: String {
        switch self {
        case .mdm:          return "MDM ✅"
        case .fallback:     return "Fallback (Hardcoded) ⚠️"
        case .userDefaults: return "UserDefaults"
        case .fireStore:    return "Firestore"
        }
    }
}
