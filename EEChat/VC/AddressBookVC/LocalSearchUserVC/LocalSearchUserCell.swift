//
//  LocalSearchUserCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/23.
//

import UIKit
import OpenIM

class LocalSearchUserCell: UITableViewCell {

    @IBOutlet var avatarView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    
    var model: UserInfo! {
        didSet {
            nameLabel.text = model.getName()
            avatarView.setImage(with: model.icon,
                                placeholder: UIImage(named: "icon_default_avatar"))
        }
    }
}
