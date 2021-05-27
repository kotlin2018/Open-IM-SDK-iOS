//
//  ApiFriend.swift
//  OpenIM
//
//  Created by Snow on 2021/5/14.
//

import Foundation

public struct ApiFriendSearch: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/search_friend")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
    }
    
    public struct Model: Decodable {
        public var userInfo = UserInfo()
        
        public var isFriend = false
        public var isInBlackList = false
        
        private enum CodingKeys: String, CodingKey {
            case isFriend,
                 isInBlackList
        }
        
        public init(from decoder: Decoder) throws {
            userInfo = try UserInfo(from: decoder)
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                let value = try container.decode(Int.self, forKey: .isFriend)
                isFriend = value == 0 ? false : true
            }
            do {
                let value = try container.decode(Int.self, forKey: .isInBlackList)
                isInBlackList = value == 0 ? false : true
            }
        }
    }
}

public struct ApiFriendSetComment: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/set_friend_comment")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
        public var comment = ""
    }
    
}

public struct ApiFriendGetList: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/get_friend_list")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
    }
    
    public typealias Model = UserInfo
}

public struct ApiFriendAddBlacklist: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/add_blacklist")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
    }
}

public struct ApiFriendRemoveBlacklist: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/remove_blacklist")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
    }
}

public struct ApiFriendGetBlacklist: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/get_blacklist")
    
    public var param = OnlyOperationID()
    
    public init() {}
    
    public typealias Model = UserInfo
}

public struct ApiFriendAddFriend: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/add_friend")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
        public var reqMessage = ""
    }
}

public enum AddFriendFlag: Int, Codable {
    case reject = -1
    case `default` = 0
    case agree = 1
}

public struct ApiFriendGetApplyList: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/get_friend_apply_list")
    
    public var param = OnlyOperationID()
    
    public init() {}
    
    public enum Flag: Int, Encodable {
        case reject = -1
        case `default` = 0
        case agree = 1
    }
    
    public class Model: Decodable {
        public var userInfo = UserInfo()
        public var applyTime = TimeInterval.zero
        public var reqMessage = ""
        public var flag = AddFriendFlag.default
        
        private enum CodingKeys: String, CodingKey {
            case applyTime,
                 reqMessage,
                 flag
        }
        
        required public init(from decoder: Decoder) throws {
            userInfo = try UserInfo(from: decoder)
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let value = try? container.decode(String.self, forKey: .applyTime),
               let doubleValue = TimeInterval(value) {
                applyTime = doubleValue
            }
            reqMessage = try container.decode(String.self, forKey: .reqMessage)
            flag = try container.decode(AddFriendFlag.self, forKey: .flag)
        }
    }
}

public struct ApiFriendAddFriendResponse: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/add_friend_response")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
        public var flag = AddFriendFlag.default
    }
}

public struct ApiFriendRemoveFriend: ApiType {
    public let apiTarget: ApiTarget = ApiInfo(path: "friend/delete_friend")
    
    public var param = Param()
    
    public init() {}
    
    public struct Param: Encodable {
        let operationID = OperationID()
        public var uid = ""
    }
}
