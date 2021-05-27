//
//  Connection.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation
import Starscream

private enum State {
    case connecting
    case connected
    case disconnected
}

private class ExpBackoffSteps {
    private let kBaseSleepMs = 500
    private let kMaxShift = 11
    private var attempt: Int = 0

    func getNextDelay() -> Int {
        if attempt > kMaxShift {
            attempt = kMaxShift
        }
        let half = UInt32(kBaseSleepMs * (1 << attempt))
        let delay = half + arc4random_uniform(half)
        attempt += 1
        return Int(delay)
    }
    func reset() {
        attempt = 0
    }
}

protocol ConnectionListener: AnyObject {
    func onConnect(reconnecting: Bool) -> Void
    func onMessage(with data: Data) -> Void
    func onDisconnect(code: Int, reason: String) -> Void
    func onError(error: Error) -> Void
}

public class Connection {
    var isConnected: Bool {
        return state == .connected
    }

    var isWaitingToConnect: Bool {
        return state == .connecting
    }
    
    private var webSocket: WebSocket
    private var request: URLRequest
    internal weak var connectionListener: ConnectionListener?
    private var state = State.disconnected
    
    private var connectQueue = DispatchQueue(label: "cn.rentsoft.connection")
    private var netEventQueue = DispatchQueue(label: "cn.rentsoft.network")
    private var autoreconnect: Bool = false
    private var reconnecting: Bool = false
    private var backoffSteps = ExpBackoffSteps()
    private var reconnectClosure: DispatchWorkItem? = nil
    
    init(open url: URL) {
        self.request = URLRequest(url: url)
        self.webSocket = WebSocket(request: request)
        self.webSocket.callbackQueue = netEventQueue
        self.webSocket.delegate = self
        
        maybeInitReconnectClosure()
    }
    
    private func maybeInitReconnectClosure() {
        if reconnectClosure?.isCancelled ?? true {
            reconnectClosure = DispatchWorkItem() {
                self.connectSocket()
                if self.state == .connected {
                    self.reconnecting = false
                    return
                }
                self.connectWithBackoffAsync()
            }
        }
    }
    
    private func connectSocket() {
        guard state == .disconnected else { return }
        self.webSocket.connect()
    }
    
    private func connectWithBackoffAsync() {
        let delay = Double(self.backoffSteps.getNextDelay()) / 1000
        maybeInitReconnectClosure()
        self.connectQueue.asyncAfter(
            deadline: .now() + delay,
            execute: reconnectClosure!)
    }
    
    @discardableResult
    func connect(reconnectAutomatically: Bool = true) -> Bool {
        self.autoreconnect = reconnectAutomatically
        if self.autoreconnect && self.reconnecting {
            reconnectClosure!.cancel()
            backoffSteps.reset()
            connectWithBackoffAsync()
        } else {
            connectSocket()
        }
        return true
    }
    
    func disconnect() {
        webSocket.disconnect()
        if autoreconnect {
            autoreconnect = false
            reconnectClosure!.cancel()
        }
    }

    func send(payload data: Data) -> Void {
        webSocket.write(data: data)
    }
}

extension Connection: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            state = .connected
            
            backoffSteps.reset()
            connectionListener?.onConnect(reconnecting: reconnecting)
            reconnecting = false
        case .disconnected(let reason, let code):
            handle(code: Int(code), reason: reason)
        case .text(let text):
            guard let data = text.data(using: .utf8) else {
                fatalError()
            }
            connectionListener?.onMessage(with: data)
        case .binary(let data):
            connectionListener?.onMessage(with: data)
        case .pong(_):
            break
        case .ping(_):
            break
        case .error(let error):
            if let error = error as? HTTPUpgradeError,
               case let HTTPUpgradeError.notAnUpgrade(code) = error {
                handle(code: code, reason: error.localizedDescription)
            } else {
                handle(code: 0, reason: error?.localizedDescription ?? "")
            }
        case .viabilityChanged(let isViable):
            if !isViable {
                handle(code: 0, reason: "")
            }
        case .reconnectSuggested(_):
            break
        case .cancelled:
            handle(code: 0, reason: "")
        }
    }
    
    private func handle(code: Int, reason: String) {
        state = .disconnected
        
        if code != 0 {
            let error = NSError(domain: "", code: code, userInfo: [NSLocalizedDescriptionKey: reason])
            connectionListener?.onError(error: error)
        }
        
        connectionListener?.onDisconnect(code: code, reason: reason)
        
        if autoreconnect {
            self.connectWithBackoffAsync()
        }
    }
}
