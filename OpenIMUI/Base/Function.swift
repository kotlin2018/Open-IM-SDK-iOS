//
//  Function.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/27.
//

import Foundation

func LocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, bundle: Bundle(for: MessagesViewController.self), comment: "")
}

public let OpenIMUILocalizedString = LocalizedString
