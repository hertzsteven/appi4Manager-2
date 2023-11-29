//
//  ApiHelper.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation

    /// Define all your ApiManager's utilities here
    struct ApiHelper {
        
        /// API Base URL
        //  MARK: -  For MYNFR
//        static let baseURL =  "https://developitsnfrEDU.jamfcloud.com/api"
//        static let apiKey = "Basic NjUzMTkwNzY6UFFMNjFaVUU2RlFOWDVKSlMzTE5CWlBDS1BETVhMSFA="
        static let classuuid = "5660a0b6-7a4c-4749-abb2-735b3476a927"


        static let company = "2001128"
        static let username = "teacherlila"
        static let password = "123456"
        
        static let clssuserGroupId = 1
        static let globalLocationId = 0

            //        static let authorizationCodeAlt = "Basic NjUzMTkwNzY6TUNTTUQ2VkM3TUNLVU5OOE1KNUNEQTk2UjFIWkJHQVY="

        //  MARK: -  for YDE
//        static let baseURL = "https://ydeschool.jamfcloud.com/api"
//        static let authorizationCode = "Basic NTM3MjI0NjA6RVBUTlpaVEdYV1U1VEo0Vk5RUDMyWDVZSEpSVjYyMkU=" // this is for yde"
//        static let classuuid = "872558bd-0c84-49aa-9023-60655fcc9ffd"
//
//        static let company = "1049131"
//        static let username = "stubTeacher"
//        static let password = "Simcha@3485"
//
//        static let clssuserGroupId = 42
//        static let globalLocationId = 3
}

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
