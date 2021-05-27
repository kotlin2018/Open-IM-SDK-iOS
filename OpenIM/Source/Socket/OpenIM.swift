//
//  OpenIM.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation
import RxSwift

public protocol OpenIMEventListener: AnyObject {
    func onConnect()
    func onDisconnect(code: Int, reason: String)
    func onMessage(msg: ServerMessage)
    func onRawMessage(rawData: Data)
    func onReceivedMessage(_ messages: [SessionType: [Message]])
}

public enum OpenIMError: LocalizedError {
    case timeout
    case notConnected(String)
}

private class ListenerNotifier: OpenIMEventListener {
    
    private var listeners: [OpenIMEventListener] = []
    private var queue = DispatchQueue(label: "cn.rentsoft.listener")

    public func addListener(_ l: OpenIMEventListener) {
        queue.sync {
            guard listeners.firstIndex(where: { $0 === l }) == nil else { return }
            listeners.append(l)
        }
    }

    public func removeListener(_ l: OpenIMEventListener) {
        queue.sync {
            if let idx = listeners.firstIndex(where: { $0 === l }) {
                listeners.remove(at: idx)
            }
        }
    }

    public var listenersThreadSafe: [OpenIMEventListener] {
        queue.sync { return self.listeners }
    }

    
    // MARK: - OpenIMEventListener
    func onConnect() {
        listenersThreadSafe.forEach{ $0.onConnect() }
    }
    
    func onDisconnect(code: Int, reason: String) {
        listenersThreadSafe.forEach{ $0.onDisconnect(code: code, reason: reason) }
    }
    
    func onMessage(msg: ServerMessage) {
        listenersThreadSafe.forEach{ $0.onMessage(msg: msg) }
    }
    
    func onRawMessage(rawData: Data) {
        listenersThreadSafe.forEach{ $0.onRawMessage(rawData: rawData) }
    }
    
    func onReceivedMessage(_ messages: [SessionType : [Message]]) {
        listenersThreadSafe.forEach{ $0.onReceivedMessage(messages) }
    }
    
}

public typealias ChatResult = Single<ServerMessage>

class OpenIM {
    
    private var observers = Synchronized([Int64: (SingleEvent<ServerMessage>) -> Void]())
    
    public var nextMsgId: Int64 = 1
    
    private func getNextMsgId() -> Int64 {
        nextMsgId += 1
        return nextMsgId
    }
    
    private func resetMsgId() {
        nextMsgId = 0xffff + Int64((Float(arc4random()) / Float(UInt32.max)) * 0xffff)
    }
    
    public var nameCounter = 0
    
    public func nextUniqueString() -> String {
        nameCounter += 1
        let millisecSince1970 = Int64(Date().timeIntervalSince1970 as Double * 1000)
        let q = ((millisecSince1970 - 1414213562373) << 16).advanced(by: nameCounter & 0xffff)
        return String(q, radix: 32)
    }
    
    var seq: Int64 = 1 {
        didSet {
            UserDefaults.standard.setValue(seq, forKey: seqCacheKey)
        }
    }
    
    public var uid: String
    public var token: String
    private let seqCacheKey: String
    
    public init(uid: String, token: String, url: URL) {
        self.uid = uid
        self.token = token
        
        guard var urlComps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            fatalError()
        }
        
        urlComps.queryItems = [
            URLQueryItem(name: "sendID", value: uid),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "platformID", value: "1")
        ]
        
        seqCacheKey = "OpenIM.\(uid).seq"
        let value = Int64(UserDefaults.standard.integer(forKey: seqCacheKey))
        if value > 0 {
            seq = value
        }
                    
        connection = Connection(open: urlComps.url!)
        connection.connectionListener = self
        connection.connect(reconnectAutomatically: true)
    }
    
    public func isMe(uid: String?) -> Bool {
        return self.uid == uid
    }
    
    private var listenerNotifier = ListenerNotifier()
    
    public func addListener(_ l: OpenIMEventListener) {
        listenerNotifier.addListener(l)
    }
    
    public func removeListener(_ l: OpenIMEventListener) {
        listenerNotifier.removeListener(l)
    }
    
    public var connection: Connection
    
    private func send<DataType: Encodable>(payload msg: ClientMessage<DataType>) throws {
        let data = try JSONEncoder().encode(msg)
        connection.send(payload: data)
    }
    
    private let scheduler: SerialDispatchQueueScheduler = {
        let label = "cn.rentsoft.scheduler"
        let queue = DispatchQueue.global()
        return SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: label)
    }()
    
    private func send<DataType: Encodable>(payload msg: ClientMessage<DataType>, with id: Int64) -> ChatResult {
        return Single<ServerMessage>.create { (observer) -> Disposable in
            self.observers.writer { dict in
                dict[id] = observer
            }
            
            do {
                try self.send(payload: msg)
            } catch {
                self.observers.writer { dict in
                    dict.removeValue(forKey: id)
                }
                observer(.failure(error))
            }
            return Disposables.create {}
        }
        .timeout(RxTimeInterval.seconds(5), scheduler: scheduler)
        .do(onError: { error in
            if case RxError.timeout = error {
                self.observers.writer { dict in
                    dict.removeValue(forKey: id)
                }
            }
        })
    }
    
    private func resolve(with id: Int64, message: ServerMessage) throws {
        self.observers.writer { dict in
            guard let observer = dict.removeValue(forKey: id) else {
                return
            }
            if message.errCode == 0 {
                observer(.success(message))
            } else {
                let error = NSError(domain: "",
                                    code: message.errCode,
                                    userInfo: [NSLocalizedDescriptionKey: message.errMsg])
                observer(.failure(error))
            }
        }
    }
    
    fileprivate func dispatch(_ data: Data) throws {
        guard !data.isEmpty else {
            return
        }
        
        listenerNotifier.onRawMessage(rawData: data)
        
        let result = try JSONDecoder().decode(ServerMessage.self, from: data)
        if let id = result.msgIncr {
            try resolve(with: id, message: result)
        }
        
        guard result.errCode == 0 else {
            return
        }
        
        switch result.reqIdentifier {
        case 2001:
            let model: MessageModel = try result.getContent()
            let message = try model.toMessage(nil, uid: self.uid)
            listenerNotifier.onReceivedMessage([message.session: [message]])
            if model.seq - seq > 1 {
                pull(start: seq, end: model.seq)
            }
            seq = model.seq
        default:
            listenerNotifier.onMessage(msg: result)
        }
        
    }
    
    private func send<Data: Encodable>(reqID: Int, data: Data? = nil) -> ChatResult {
        let msgID =  getNextMsgId()
        let msg = ClientMessage(reqID, sendID: uid, token: token, msgIncr: msgID, data: data)
        return send(payload: msg, with: msgID)
    }

    // MARK: - Function
    
    private func pullMaxSeq() {
        struct Model: Decodable {
            let seq: Int64
        }
        
        _ = send(reqID: 1001, data: Int?(nil))
            .map({ result -> Model in
                return try result.getContent()
            })
            .subscribe(onSuccess: { model in
                self.pull(start: self.seq, end: model.seq)
            })
    }
    
    private func pull(start: Int64, end: Int64) {
        struct Param: Encodable {
            let seqBegin: Int64
            let seqEnd: Int64
        }
        
        struct Model: Decodable {
            struct List: Decodable {
                var id = ""
                var list: [MessageModel] = []
            }
            
            var minSeq = Int64.zero
            var maxSeq = Int64.zero
            var single: [List] = []
            var group: [List] = []
        }
        
        guard start < end else {
            return
        }
        
        self.seq = end
        
        let param = Param(seqBegin: start, seqEnd: end)
        _ = send(reqID: 1002, data: param)
            .map({ result -> [SessionType : [Message]] in
                let model: Model = try result.getContent()
                
                var map: [SessionType: [Message]] = [:]
                try model.single.forEach { list in
                    let session = SessionType.p2p(list.id)
                    map[session] = try list.list.map(MessageModel.mapBlock(session, uid: self.uid))
                }
                try model.group.forEach { list in
                    let session = SessionType.group(list.id)
                    map[session] = try list.list.map(MessageModel.mapBlock(session, uid: self.uid))
                }
                return map
            })
            .subscribe(onSuccess: { map in
                if !map.isEmpty {
                    self.listenerNotifier.onReceivedMessage(map)
                }
            })
    }
    
    func send(message: Message) -> Single<String> {
        struct Param: Encodable {
            let platformID = 1
            let sessionType: Int
            let msgFrom: Int
            let contentType: Int
            
            let recvID: String
            let content: String
            var forceList: [String] = []
            
            var options: [String: String] = [:]
            var clientMsgID = ""
            var offlineInfo: [String: String] = [:]
            var ext: [String: String] = [:]
            
            init(_ session: SessionType, contentType: Int, content: String) {
                let (type, id) = session.session()
                self.sessionType = type
                self.msgFrom = (contentType / 100) * 100
                self.contentType = contentType
                self.recvID = id
                self.content = content
            }
        }
        
        struct Model: Decodable {
            let serverMsgID: String
        }
        
        let (type, content) = try! message.content.content()
        var param = Param(message.session, contentType: type, content: content)
        param.clientMsgID = message.messageId
        
        return send(reqID: 1003, data: param)
            .map { result -> String in
                let model: Model = try result.getContent()
                return model.serverMsgID
            }
    }
    
}

// MARK: - ConnectionListener

extension OpenIM: ConnectionListener {
    func onConnect(reconnecting: Bool) {
        listenerNotifier.onConnect()
        pullMaxSeq()
    }
    
    func onMessage(with data: Data) {
        do {
            try dispatch(data)
        } catch {
            
        }
    }
    
    func onDisconnect(code: Int, reason: String) {
        listenerNotifier.onDisconnect(code: code, reason: reason)
        
        let error = OpenIMError.notConnected(reason)
        observers.value.values.forEach { observer in
            observer(.failure(error))
        }
        observers.value = [:]
    }
    
    func onError(error: Error) {
        
    }
}
