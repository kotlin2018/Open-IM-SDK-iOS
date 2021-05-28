//
//  DBModule.swift
//  OpenIM
//
//  Created by Snow on 2021/5/18.
//

import Foundation
import GRDB

public class DBModule {
    
    let database: DatabaseWriter
    
    init(id: String) {
        let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first! + "/OpenIM/\(id)/"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        database = try! DatabasePool(path: path + "db.sqlite")
        createTable()
    }
    
    private func createTable() {
        try! database.write({ (db) -> Void in
            try? db.create(table: Message.databaseTableName, body: { t in
                t.column("messageId", .text).primaryKey()
                
                t.column("session", .text)
                t.column("contentType", .integer)
                t.column("content", .text)
                
                t.column("recvID", .text)
                t.column("sendID", .text)
                
                t.column("sendTime", .double)
                t.column("status", .integer)
            })
            
            try? db.create(table: UserInfo.databaseTableName, body: { t in
                t.column("uid", .text).primaryKey()
                t.column("name", .text)
                t.column("icon", .text)
                t.column("gender", .integer)
                t.column("mobile", .text)
                t.column("birth", .text)
                t.column("email", .text)
                t.column("ex", .text)
                t.column("comment", .text)
            })
            
            try? db.create(table: Session.databaseTableName, body: { t in
                t.column("session", .text).primaryKey()
                t.column("isTop", .integer)
                t.column("text", .text)
                t.column("date", .double)
                t.column("unread", .integer)
            })
        })
    }
    
    // MARK: - Message
    
    public func fetch(_ sessionType: SessionType, count: Int, offset msgID: String) -> [Message] {
        let messages = try! database.read({ db -> [Message] in
            return try! Message.fetchAll(
                db,
                sql:"""
                    SELECT * FROM \(Message.databaseTableName)
                    WHERE session = :session
                    ORDER BY sendTime DESC
                    LIMIT :count
                    OFFSET (
                        SELECT coalesce(MAX(rowNum), 0)
                        FROM (
                            SELECT messageId, ROW_NUMBER() OVER (ORDER BY sendTime DESC) AS rowNum
                            FROM message
                        ) AS rowTable
                        WHERE messageId = :msgID
                    )
                    """,
                arguments: [
                    "session": sessionType.description,
                    "count": count,
                    "msgID": msgID,
                ]
            )
        })
        return messages.reversed()
    }
    
    func fetch(_ sessionType: SessionType, type: ContentType.`Type`, key: String = "") -> [Message] {
        return try! database.read({ db in
            return try! Message.fetchAll(
                db,
                sql:"""
                    SELECT * FROM \(Message.databaseTableName)
                    WHERE session = :session AND contentType = :contentType AND content LIKE :key
                    ORDER BY sendTime
                    """,
                arguments: [
                    "session": sessionType.description,
                    "contentType": type.rawValue,
                    "key": "%\(key)%",
                ]
            )
        })
    }
    
    public func save(_ message: Message) {
        database.asyncBarrierWriteWithoutTransaction { db in
            try! message.save(db)
        }
    }
    
    public func save(_ array: [Message]) {
        database.asyncBarrierWriteWithoutTransaction { db in
            array.forEach { message in
                if message.isDisplay {
                    try! message.save(db)
                }
            }
        }
    }
    
    public func update(message: Message, oldMsgID: String? = nil) {
        database.asyncBarrierWriteWithoutTransaction { db in
            try! db.execute(
                sql: """
                    UPDATE \(Message.databaseTableName)
                    SET status = :status, messageId = :new
                    WHERE messageId = :old
                    """,
                arguments: [
                    "status": message.status,
                    "old": oldMsgID ?? message.messageId,
                    "new": message.messageId,
                ]
            )
        }
    }
    
    public func delete(_ messages: [Message]) {
        database.asyncBarrierWriteWithoutTransaction { db in
            messages.forEach { message in
                try! message.delete(db)
            }
        }
    }
    
    public func deleteAllMessage(_ sessionType: SessionType) {
        database.asyncBarrierWriteWithoutTransaction { db in
            try! db.execute(
                sql: """
                    DELETE FROM \(Message.databaseTableName)
                    WHERE session=:session
                    """,
                arguments: ["session": sessionType.description])
        }
    }
    
    // MARK: - UserInfo
    
    public func fetchAll() -> [UserInfo] {
        return try! database.read({ db in
            return try! UserInfo.fetchAll(db)
        })
    }
    
    public func save(_ userInfo: UserInfo) {
        database.asyncBarrierWriteWithoutTransaction { db in
            try! userInfo.save(db)
        }
    }
    
    public func save(_ array: [UserInfo]) {
        database.asyncBarrierWriteWithoutTransaction { db in
            array.forEach { userInfo in
                try! userInfo.save(db)
            }
        }
    }
    
    public func fetchFriends(_ key: String) -> [UserInfo] {
        return try! database.read({ db in
            return try! UserInfo.fetchAll(
                db,
                sql: """
                    SELECT * FROM \(UserInfo.databaseTableName)
                    WHERE name LIKE :key OR comment LIKE :key
                    """,
                arguments: ["key": "%\(key)%"])
        })
    }
    
    // MARK: - Session
    
    public func fetchAll() -> [Session] {
        return try! database.read({ db in
            return try! Session.fetchAll(
                db,
                sql:"""
                    SELECT * FROM \(Session.databaseTableName)
                    ORDER BY date DESC
                    """
            )
        })
    }
    
    public func save(_ array: [Session]) {
        database.asyncBarrierWriteWithoutTransaction { db in
            array.forEach { session in
                try! session.save(db)
            }
        }
    }
    
    public func delete(_ session: Session) {
        database.asyncBarrierWriteWithoutTransaction { db in
            try? session.delete(db)
        }
    }

}
