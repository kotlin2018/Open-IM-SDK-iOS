//
//  ApiUser.swift
//  OpenIM
//
//  Created by Snow on 2021/5/14.
//

import Foundation
import GRDB

public struct ApiUserUpdateInfo: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "user/update_user_info")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        
        public var name: String?
        public var icon: String?
        public var gender: Gender?
        public var mobile: String?
        public var birth: String?
        public var email: String?
        public var ex: String?
    }
}

public class UserInfo: Codable, Hashable, FetchableRecord, PersistableRecord {
    public var uid = ""
    public var name = ""
    public var icon: URL?
    public var gender = Gender.unknown
    public var mobile = ""
    public var birth = ""
    public var email = ""
    public var ex = ""
    public var comment = ""
    
    public init() {}
    
    private enum CodingKeys: String, CodingKey {
        case uid, name, icon, gender, mobile, birth, email, ex, comment
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        name = try container.decode(String.self, forKey: .name)
        icon = try? container.decode(URL.self, forKey: .icon)
        gender = try container.decode(Gender.self, forKey: .gender)
        mobile = try container.decode(String.self, forKey: .mobile)
        birth = try container.decode(String.self, forKey: .birth)
        email = try container.decode(String.self, forKey: .email)
        ex = try container.decode(String.self, forKey: .ex)
        if let value = try? container.decode(String.self, forKey: .comment) {
            comment = value
        }
    }
    
    public static func == (lhs: UserInfo, rhs: UserInfo) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    public func getName() -> String {
        return comment.isEmpty ? name : comment
    }
}

public struct ApiUserGetInfo: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "user/get_user_info")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        
        public var uidList: [String] = []
    }
    
    public typealias Model = UserInfo
}
