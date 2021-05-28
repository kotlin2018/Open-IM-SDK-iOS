//
//  Message.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation
import GRDB

public struct MediaItem: Codable, Hashable {
    public let url: URL?
    public let thumbnail: URL?
    
    public let width: Int
    public let height: Int
    
    public init(url: URL?, thumbnail: URL?, width: Int, height: Int) {
        self.url = url
        self.thumbnail = thumbnail
        self.width = width
        self.height = height
    }
}

public struct AudioItem: Codable {
    public let url: URL?
    public let duration: Int
    
    public init(url: URL?, duration: Int) {
        self.url = url
        self.duration = duration
    }
}

public struct SystemItem: Codable {
    
    public let isDisplay: Int
    public let id: String
    public let text: String
    
}

public class Message: Codable, Hashable, FetchableRecord, PersistableRecord {
    
    public enum Status: UInt16, Codable, DatabaseValueConvertible {
        case `init` = 0x0000   
        case uploading = 0x0001
        case failure = 0x0100
        case sending = 0x0101
        case sent = 0x0102
        
        case received = 0x1000
        case watched = 0x1001
        case clicked = 0x1002
    }
    
    public var messageId = ""
    
    public var session = SessionType.p2p("")
    public var content = ContentType.text("")
    
    public var recvID = ""
    public var sendID = ""
    
    public var sendTime = TimeInterval.zero
    
    public var status = Status.`init`
    
    public var isDisplay: Bool {
        if case let ContentType.system(_, item) = content {
            if item.isDisplay == 0 {
                return false
            }
        }
        return true
    }
    
    public var isSystem: Bool {
        if case ContentType.system = content {
            return true
        }
        return false
    }
    
    public var isFromCurrentSender: Bool {
        return status.rawValue < Status.received.rawValue
    }
    
    public init() {}
    
    private enum CodingKeys: String, CodingKey {
        case messageId,
             session, content,
             recvID, sendID,
             sendTime, status
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try container.decode(String.self, forKey: .messageId)
        session = try container.decode(SessionType.self, forKey: .session)
        content = try ContentType(from: decoder)
        
        recvID = try container.decode(String.self, forKey: .recvID)
        sendID = try container.decode(String.self, forKey: .sendID)
        
        sendTime = try container.decode(TimeInterval.self, forKey: .sendTime)
        
        status = try container.decode(Status.self, forKey: .status)
        
        if status.rawValue < Status.sent.rawValue {
            status = .failure
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(session, forKey: .session)
        try content.encode(to: encoder)
        
        try container.encode(recvID, forKey: .recvID)
        try container.encode(sendID, forKey: .sendID)
        try container.encode(sendTime, forKey: .sendTime)
        try container.encode(status, forKey: .status)
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.session == rhs.session && lhs.messageId == rhs.messageId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
        session.hash(into: &hasher)
    }
}
