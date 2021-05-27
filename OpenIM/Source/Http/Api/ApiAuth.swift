//
//  ApiAuth.swift
//  Alamofire
//
//  Created by Snow on 2021/5/14.
//

import Foundation
import GRDB

public struct OperationID: Encodable {
    
    public init() {}
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = OpenIMManager.shared.model.uid + "." + String(Int64(Date().timeIntervalSince1970))
        try container.encode(value)
    }
}

public struct OnlyOperationID: Encodable {
    let operationID = OperationID()
    
    public init() {}
}

public enum Gender: Int, Codable, DatabaseValueConvertible {
    case unknown = 0
    case male = 1
    case female = 2
}

public struct ApiAuthUserRegister: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "auth/user_register")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let platform = 1
        
        public var secret = ""
        public var uid = ""
        public var name = ""
        public var icon: String?
        public var gender: Gender?
        public var mobile: String?
        public var birth: String?
        public var email: String?
        public var ex: String?
    }
}

public struct ApiAuthToken: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "auth/user_token")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let platform = 1
        
        public var secret = ""
        public var uid = ""
    }
    
    public struct Model: Codable {
        public var uid = ""
        public var token = ""
        public var expiredTime = TimeInterval.zero
        
        public init() {}
    }
}
