//
//  OpenIMManager.swift
//  OpenIM
//
//  Created by Snow on 2021/5/14.
//

import Foundation
import RxSwift

extension OpenIMManager {
    public static let deleteMessageNotification = Notification.Name("OpenIMManager.deleteMessageNotification")
    public static let deleteAllMessageNotification = Notification.Name("OpenIMManager.deleteAllMessageNotification")
    public static let updateSessionNotification = Notification.Name("OpenIMManager.updateSessionNotification")
}

public protocol OpenIMHandleMessageDelegate: AnyObject {
    func handleMessage(_ messages: [Message])
    func handleSystemMessage(_ messages: [Message])
}

public extension OpenIMHandleMessageDelegate {
    func handleMessage(_ messages: [Message]) {
        
    }
    
    func handleSystemMessage(_ messages: [Message]) {
        
    }
}

extension OpenIMManager {
    struct AnyObserver {
        weak var base: OpenIMHandleMessageDelegate?
        init(_ base: OpenIMHandleMessageDelegate?) {
            self.base = base
        }
    }
}

public class OpenIMManager {
    
    public static let shared = OpenIMManager()
    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    public private(set) var model = ApiAuthToken.Model()
    
    func isLogin() -> Bool {
        return model.token != ""
    }
    
    public func login(model: ApiAuthToken.Model) {
        self.model = model
        let url = URL(string: "ws://47.112.160.66:7778")!
        self.chat = OpenIM(uid: model.uid, token: model.token, url: url)
        self.chat?.addListener(self)
        self.db = DBModule(id: model.uid)
        guard let db = db else {
            fatalError()
        }
        
        db.fetchAll().forEach { userInfo in
            userDict[userInfo.uid] = userInfo
        }
        
        sessions.value = Set(db.fetchAll())
    }
    
    public func logout() {
        saveUsers()
        saveSession()
        
        model = ApiAuthToken.Model()
        db = nil
        userDict.removeAll()
        sessions.value = Set()
    }
    
    @objc
    private func didEnterBackgroundNotification() {
        saveUsers()
        saveSession()
    }
    
    private var listeners: [SessionType: [AnyObserver]] = [:]
    
    public func addListener(_ sessionType: SessionType, listener: OpenIMHandleMessageDelegate) {
        var array = listeners[sessionType]?.filter{ $0.base != nil } ?? []
        array.append(AnyObserver(listener))
        listeners[sessionType] = array
    }
    
    public func removeListener(_ sessionType: SessionType, listener: OpenIMHandleMessageDelegate) {
        listeners[sessionType]?.removeAll(where: { observer in
            return observer.base === listener
        })
    }
    
    // MARK: - Chat
    
    private(set) var chat: OpenIM?
    
    public func send(_ sessionType: SessionType, text: String, callback: ((Message) -> Void)? = nil) -> Message {
        return send(sessionType, content: .text(text), callback: callback)
    }
    
    @discardableResult
    public func send(_ sessionType: SessionType, content: ContentType, callback: ((Message) -> Void)? = nil) -> Message {
        let message = Message()
        message.session = sessionType
        message.content = content
        send(message, callback: callback)
        return message
    }
    
    public func send(_ message: Message, callback: ((Message) -> Void)? = nil) {
        
        func callbackBlock(_ message: Message, oldMsgID: String? = nil, callback: ((Message) -> Void)?) {
            callback?(message)
            db?.update(message: message, oldMsgID: oldMsgID)
        }
        
        if message.messageId.isEmpty {
            message.sendID = model.uid
            message.messageId = UUID().uuidString
            message.sendTime = Date().timeIntervalSince1970
            onReceivedMessage([message.session: [message]])
        }
        
        guard let chat = chat else {
            message.status = .failure
            callbackBlock(message, callback: callback)
            return
        }
        
        message.status = .sending
        _ = chat.send(message: message)
            .subscribe(onSuccess: { msgID in
                let oldMsgID = message.messageId
                message.messageId = msgID
                message.status = .sent
                callbackBlock(message, oldMsgID: oldMsgID, callback: callback)
            }, onFailure: { _ in
                message.status = .failure
                callbackBlock(message, callback: callback)
            })
    }
    
    // MARK: - DB
    
    private(set) var db: DBModule?
    
    private var sessions = Synchronized(Set<Session>())
    
    public func getSessions() -> [Session] {
        return Array(sessions.value)
    }
    
    public func update(_ sessionType: SessionType, message: Message? = nil) {
        if let session = sessions.value.first(where: { $0.session == sessionType }) {
            session.unread = 0
            if let message = message {
                session.date = message.sendTime
                session.text = message.content.description
            } else {
                session.text = ""
            }
        }
    }
    
    // MARK: - Session
    
    public func update(session: Session) {
        sessions.writer { set in
            set.insert(session)
        }
    }
    
    public func delete(session: Session) {
        sessions.writer { set in
            set.remove(session)
        }
        self.db?.delete(session)
    }
    
    public func deleteSession(_ sessionType: SessionType) {
        sessions.writer { set in
            if let session = set.first(where: { $0.session == sessionType }) {
                set.remove(session)
                self.db?.delete(session)
            }
        }
    }
    
    public func getSession(_ sessionType: SessionType) -> Session? {
        return sessions.reader { set in
            return set.first(where: { $0.session == sessionType })
        }
    }
    
    private func saveSession() {
        db?.save(Array(sessions.value))
    }
    
    public var badgeNumber: Int {
        return Array(sessions.value).reduce(into: 0) { result, session in
            result += session.unread
        }
    }
    
    // MARK: - User
    
    public private(set) var userDict: [String: UserInfo] = [:]
    public func getUser(uid: String) -> UserInfo? {
        return userDict[uid]
    }
    
    public func update(_ userInfo: UserInfo) {
        userDict[userInfo.uid] = userInfo
    }
    
    public func update(uids: [String], callback: (() -> Void)? = nil ) {
        var api = ApiUserGetInfo()
        api.param.uidList = uids
        _ = api.request(showError: false)
            .map(type: [ApiUserGetInfo.Model].self)
            .subscribe(onSuccess: { array in
                array.forEach { userInfo in
                    self.userDict[userInfo.uid] = userInfo
                }
                callback?()
            })
    }
    
    private func saveUsers() {
        let array = userDict.map{ $0.value }
        db?.save(array)
    }
    
    public func fetchFriends(_ key: String) -> [UserInfo] {
        let array = db?.fetchFriends(key) ?? []
        return array.filter{ $0.uid != model.uid }
    }
    
    // MARK: - Message
    
    public func update(message: Message) {
        db?.update(message: message)
    }
    
    public func fetch(_ session: SessionType, count: Int = 50, offset msgID: String) -> [Message] {
        return db?.fetch(session, count: count, offset: msgID) ?? []
    }
    
    public func fetch(_ sessionType: SessionType, type: ContentType.`Type`, key: String = "") -> [Message] {
        return db?.fetch(sessionType, type: type, key: key) ?? []
    }
    
    public func delete(_ messages: [Message]) {
        db?.delete(messages)
        NotificationCenter.default.post(name: OpenIMManager.deleteMessageNotification, object: messages)
    }
    
    public func deleteAllMessage(_ sessionType: SessionType) {
        db?.deleteAllMessage(sessionType)
        NotificationCenter.default.post(name: OpenIMManager.deleteAllMessageNotification, object: sessionType)
    }
}

extension OpenIMManager: OpenIMEventListener {
    public func onConnect() {
        
    }
    
    public func onDisconnect(code: Int, reason: String) {
        
    }
    
    public func onMessage(msg: ServerMessage) {
        
    }
    
    public func onRawMessage(rawData: Data) {
        
    }
    
    public func onReceivedMessage(_ messages: [SessionType : [Message]]) {
        messages.forEach { (key: SessionType, value: [Message]) in
            self.db?.save(value)
            let session: Session
            if let value = sessions.value.first(where: { $0.session == key }) {
                session = value
            } else {
                session = Session()
                session.session = key
                update(session: session)
            }
            
            value.forEach { message in
                if message.status == .received {
                    session.unread += 1
                } else {
                    session.unread = 0
                }
            }
            
            if let message = value.last {
                session.date = message.sendTime
                session.text = message.content.description
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: OpenIMManager.updateSessionNotification, object: self)
                if let observers = self.listeners[key] {
                    let systemMessages = value.filter { $0.isSystem }
                    observers.forEach({ observer in
                        observer.base?.handleMessage(value)
                        observer.base?.handleSystemMessage(systemMessages)
                    })
                }
            }
        }
    }
}
