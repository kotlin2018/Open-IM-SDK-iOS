//
//  MessagesVC+Local.swift
//  EEChat
//
//  Created by Snow on 2021/5/19.
//

import UIKit
import OpenIM

extension MessagesVC {
    class func show(_ sessionType: SessionType) {
        let vc = self.vc(sessionType)
        NavigationModule.shared.push(vc)
    }
}
