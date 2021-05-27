//
//  HUDDelegate.swift
//  Alamofire
//
//  Created by Snow on 2021/5/18.
//

import Foundation

public protocol HUDDelegate: AnyObject {
    func showHUD(text: String)
    func hideHUD(animated: Bool)
    func showMessage(error: Error)
}
