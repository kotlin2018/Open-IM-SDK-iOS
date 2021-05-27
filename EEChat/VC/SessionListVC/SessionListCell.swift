//
//  SessionListCell.swift
//  EEChat
//
//  Created by Snow on 2021/5/25.
//

import UIKit
import OpenIM
import OpenIMUI

class SessionListCell: UITableViewCell {
    
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var unreadLabel: UILabel!

    var model: Session! {
        didSet {
            if let userInfo = OpenIMManager.shared.getUser(uid: model.session.id) {
                avatarView.setImage(with: userInfo.icon,
                                    placeholder: UIImage(named: "icon_default_avatar"))
                nameLabel.text = userInfo.getName()
            }
            contentLabel.text = OpenIMUILocalizedString(model.text)
            timeLabel.text = OpenIMDateFormatter.shared.format(model.date)
            unreadLabel.superview?.isHidden = model.unread == 0
            unreadLabel.text = model.unread < 99 ? model.unread.description : "99+"
        }
    }
    
}
