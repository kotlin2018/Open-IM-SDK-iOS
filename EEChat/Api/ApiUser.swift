//
//  ApiUser.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import Foundation
import OpenIM
import web3swift

struct ApiUserLogin: ApiType {
    let apiTarget: ApiTarget = ApiInfo(path: "user/login")
    
    var param = Param()
    
    init() {}
    
    struct Param: Encodable {
        let platform = 1
        let operationID = OperationID()
        var account = ""
        var password = ""
    }
    
    struct ToeknModel: Codable {
        var accessToken = ""
        var expiredTime = TimeInterval.zero
    }
    
    struct Model: Codable {
        var userInfo = UserInfo()
        var openImToken = ApiAuthToken.Model()
        var token = ToeknModel()
        
        init() {}
        
        private enum CodingKeys: String, CodingKey {
            case userInfo,
                 openImToken,
                 token
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let value = try? container.decode(UserInfo.self, forKey: .userInfo) {
                userInfo = value
            } else {
                userInfo = try UserInfo(from: decoder)
            }
            
            openImToken = try container.decode(ApiAuthToken.Model.self, forKey: .openImToken)
            token = try container.decode(ToeknModel.self, forKey: .token)
        }
    }
    
    static func login(mnemonic: String) {
        MessageModule.showHUD(text: LocalizedString("Generating..."))
        DispatchQueue.global().async {
            let keystore = try? BIP32Keystore(
                    mnemonics: mnemonic,
                    password: "web3swift",
                    mnemonicsPassword: "",
                    language: .english)
            
            DispatchQueue.main.async {
                MessageModule.hideHUD()
                guard let address = keystore?.addresses?.first?.address else {
                    MessageModule.showMessage(text: LocalizedString("Mnemonic word error."))
                    return
                }
                
                var api = ApiUserLogin()
                api.param.account = address
                api.param.password = "123456"
                _ = api.request(showLoading: true)
                    .map(type: ApiUserLogin.Model.self)
                    .subscribe(onSuccess: { model in
                        DBModule.shared.set(key: LoginVC.cacheKey, value: mnemonic)
                        AccountManager.shared.login(model: model)
                    })
            }
        }
    }
    
}
