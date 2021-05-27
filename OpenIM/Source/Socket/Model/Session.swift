//
//  Session.swift
//  OpenIM
//
//  Created by Snow on 2021/5/19.
//

import Foundation
import GRDB

public class Session: Codable, Hashable, FetchableRecord, PersistableRecord {
    
    public var isTop = false
    public var session = SessionType.p2p("")
    public var text = ""
    public var date = TimeInterval.zero
    public var unread = 0
    
    public init() {}
    
    public static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.session == rhs.session
    }
    
    public func hash(into hasher: inout Hasher) {
        session.hash(into: &hasher)
    }
    
}
