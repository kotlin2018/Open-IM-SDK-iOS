//
//  ClientMessage.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation

struct ClientMessage<DataType: Encodable>: Encodable {
    let reqIdentifier: Int
    let msgIncr: Int64
    
    let sendID: String
    let token: String
    let operationID: String
    let data: DataType?
    
    init(_ reqID: Int, sendID: String, token: String, msgIncr: Int64, data: DataType? = nil) {
        self.reqIdentifier = reqID
        self.msgIncr = msgIncr
        
        self.sendID = sendID
        self.token = token
        self.operationID = "\(sendID).\(Int(Date().timeIntervalSince1970))"
        self.data = data
    }
    
}



