//
//  ServerMessage.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation

public class ServerMessage: Decodable {
    let errCode: Int
    let errMsg: String
    
    let reqIdentifier: Int32
    let msgIncr: Int64?
    
    private enum CodingKeys: String, CodingKey {
        case errCode,
             errMsg,
             reqIdentifier,
             msgIncr,
             data
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.errCode = try container.decode(Int.self, forKey: .errCode)
        self.errMsg = try container.decode(String.self, forKey: .errMsg)
        self.reqIdentifier = (try? container.decode(Int32.self, forKey: .reqIdentifier)) ?? 0
        self.msgIncr = try? container.decode(Int64.self, forKey: .msgIncr)
        self.container = container
    }
    
    private var container: KeyedDecodingContainer<CodingKeys>
    public func getContent<T: Decodable>() throws -> T {
        let value = try container.decode(T.self, forKey: .data)
        return value
    }
}

struct MessageModel: Decodable {
    var sendID = ""
    var recvID = ""
    var sessionType: Int?
    var sendTime = TimeInterval.zero
    var contentType = 0
    var content = ""
    var seq = Int64.zero
    var serverMsgID = ""
    
    func toMessage(_ session: SessionType?, uid: String) throws -> Message {
        assert(session != nil || sessionType != nil)
        let isSender = sendID == uid
        let message = Message()
        message.messageId = serverMsgID
        if let session = session {
            message.session = session
        } else if let sessionType = sessionType {
            let id: String = {
                if sessionType == 1 {
                    return isSender ? recvID : sendID
                }
                return recvID
            }()
            message.session = SessionType(type: sessionType, id: id)
        }
        message.content = try ContentType(contentType, content: content)
        message.sendID = sendID
        message.recvID = recvID
        message.sendTime = sendTime
        message.status = isSender ? .sent : .received
        return message
    }
    
    static func mapBlock(_ session: SessionType, uid: String) -> (MessageModel) throws -> Message {
        return { model throws -> Message in
            return try model.toMessage(session, uid: uid)
        }
    }
}

