//
//  Enum.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation

public enum SessionType: Codable, Hashable, CustomStringConvertible {
    
    case p2p(String)
    case group(String)
        
    public init(type: Int, id: String) {
        switch type {
        case 1:
            self = .p2p(id)
        case 2:
            self = .group(id)
        default:
            fatalError()
        }
    }
    
    public init(_ str: String) throws {
        let array = str.split(separator: ",").map{ String($0) }
        guard array.count == 2, let type = Int(array[0]) else {
            fatalError()
        }
        
        let id = array[1]
        self.init(type: type, id: id)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
    
    public var description: String {
        let (type, id) = session()
        return "\(type),\(id)"
    }
    
    public func session() -> (Int, String) {
        switch self {
        case .p2p(let id):
            return (1, id)
        case .group(let id):
            return (2, id)
        }
    }
    
    public var id: String {
        switch self {
        case .p2p(let id):
            return id
        case .group(let id):
            return id
        }
    }
}

public enum Operation: Int, Codable {
    case askedAddFriend = 201
    case agreedAddFriend = 202
}

extension ContentType {
    public enum `Type`: Int, Codable {
        case text = 101
        case image = 102
        case audio = 103
        case video = 104
    }
}

public enum ContentType: Codable, CustomStringConvertible {
    case text(String)
    case image(MediaItem)
    case audio(AudioItem)
    case video(MediaItem)
    case system(Operation, SystemItem)
    case unknown(Int, String)
    
    private enum CodingKeys: String, CodingKey {
        case content,
             contentType
    }
    
    init(_ type: Int, content: String) throws {
        func decode<Content: Decodable>() throws -> Content {
            let data = content.data(using: .utf8) ?? Data()
            return try JSONDecoder().decode(Content.self, from: data)
        }
        
        guard let type = `Type`(rawValue: type) else {
            if let op = Operation(rawValue: type), let item: SystemItem = try? decode() {
                self = .system(op, item)
            } else {
                self = .unknown(type, content)
            }
            return
        }
        
        switch type {
        case .text:
            self = .text(content)
        case .image:
            let item: MediaItem = try decode()
            self = .image(item)
        case .audio:
            let item: AudioItem = try decode()
            self = .audio(item)
        case .video:
            let item: MediaItem = try decode()
            self = .video(item)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Int.self, forKey: .contentType)
        let content = try container.decode(String.self, forKey: .content)
        try self.init(type, content: content)
    }
    
    public func content() throws -> (Int, String) {
        func encode<Content: Encodable>(_ content: Content) throws -> String {
            let data = try JSONEncoder().encode(content)
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        switch self {
        case .text(let text):
            return (`Type`.text.rawValue, text)
        case .image(let item):
            return (`Type`.image.rawValue, try encode(item))
        case .audio(let item):
            return (`Type`.audio.rawValue, try encode(item))
        case .video(let item):
            return (`Type`.video.rawValue, try encode(item))
        case .system(let op, let item):
            return (op.rawValue, try encode(item))
        case .unknown(let type, let content):
            return (type, content)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        let (type, content) = try content()
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .contentType)
        try container.encode(content, forKey: .content)
    }
    
    public var description: String {
        switch self {
        case .text(let text):
            return text
        case .image:
            return "[Image]"
        case .audio:
            return "[Audio]"
        case .video:
            return "[Video]"
        case .system(_, let item):
            return item.text
        case .unknown:
            return "[Unknown]"
        }
    }
}
