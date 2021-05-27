//
//  ChatVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/25.
//

import UIKit

class ChatVC: MessagesVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "chat_icon_more")?
                                                                .withRenderingMode(.alwaysOriginal),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(friendSettingAction))
    }
    
    // MARK: - Action
    
    @objc
    func friendSettingAction() {
        FriendSettingVC.show(param: sessionType.id)
    }
    
}
