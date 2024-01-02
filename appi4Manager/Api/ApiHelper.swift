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
    let apiKey:         String
    let asset:          String
    let udid:           String
    let companyId:      Int
    let helpurl:        String

    // Singleton instance
    static let shared: APISchoolInfo = {
        guard let networkVariables = getValuesFromManagedConfigFile() else {
        return APISchoolInfo(urlEndPoint:   "https://developitsnfrEDU.jamfcloud.com/api",
                             apiKey:        "Basic NjUzMTkwNzY6UFFMNjFaVUU2RlFOWDVKSlMzTE5CWlBDS1BETVhMSFA=",
                             asset:         "asset",
                             udid:          "udid",
                             companyId:     2001128,
                             helpurl:       "www.help.com")
        }

        return APISchoolInfo(urlEndPoint:   networkVariables.companyUrl,
                             apiKey:        networkVariables.apiKey,
                             asset:         networkVariables.asset,
                             udid:          networkVariables.udid,
                             companyId:     networkVariables.CompanyId,
                             helpurl:       networkVariables.helpurl)
    }()

    // Private initializer
    private init(urlEndPoint:   String,
                 apiKey:        String,
                 asset:         String,
                 udid:          String,
                 companyId:     Int,
                 helpurl:       String) {
        self.companyUrl  = urlEndPoint
        self.apiKey       = apiKey
        self.asset        = asset
        self.udid         = udid
        self.companyId    = companyId
        self.helpurl      = helpurl
    }

    static private func getValuesFromManagedConfigFile() -> NetworkConnectionVariables? {

        guard let managedConfigObj = UserDefaults.standard.object(forKey: AppConfigKeys.fileName ) else {
               return nil
          }
          
          guard let managedConfigDict = managedConfigObj as?  [String:Any?]  else {
              return nil
          }


          guard let thecompanyUrl         = managedConfigDict[AppConfigKeys.companyUrl] as?  String  else {
              return nil
          }
          guard let theapi                = managedConfigDict[AppConfigKeys.api] as?  String  else {
              return nil
          }
          guard let theasset              = managedConfigDict[AppConfigKeys.asset] as?  String  else {
              return nil
          }
          guard let theudid               = managedConfigDict[AppConfigKeys.udid] as?  String  else {
              return nil
          }
          guard let theCompanyId          = managedConfigDict[AppConfigKeys.companyId] as?  Int  else {
              return nil
          }
          guard let thehelpurl            = managedConfigDict[AppConfigKeys.helpurl] as?  String  else {
              return nil
          }
          
          let networkConnectionVariables  = NetworkConnectionVariables(companyUrl               : thecompanyUrl,
                                                                      apiKey                    : theapi,
                                                                      asset                     : theasset,
                                                                      udid                      : theudid,
                                                                      CompanyId                 : theCompanyId,
                                                                      helpurl                   : thehelpurl,
                                                                      sourceOfNetworkProperties : .mdm)
          
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
    case mdm, userDefaults, fireStore
}
