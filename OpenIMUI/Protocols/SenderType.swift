//
//  SenderType.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/8.
//

import Foundation

public protocol SenderType {
    
    var senderId: String { get }
    
    var displayName: String { get }
    
    var avatarUrl: URL? { get }
}
