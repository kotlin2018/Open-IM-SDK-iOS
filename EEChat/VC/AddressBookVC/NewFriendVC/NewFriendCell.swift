//
//  NewFriendCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/21.
//

import UIKit
import OpenIM

class NewFriendCell: UITableViewCell {

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addBtn: UIButton!
    
    var model: ApiFriendGetApplyList.Model! {
        didSet {
            refresh()
        }
    }
    
    private func refresh() {
        let userInfo = model.userInfo
        avatarImageView.setImage(with: userInfo.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        
        nameLabel.text = userInfo.getName()
        switch model.flag {
        case .`default`:
            addBtn.isUserInteractionEnabled = true
            addBtn.backgroundColor = UIColor.eec.rgb(0x1B72EC)
            addBtn.setTitleColor(.white, for: .normal)
            addBtn.setTitle(LocalizedString("Add"), for: .normal)
        case .agree:
            fallthrough
        case .reject:
            addBtn.isUserInteractionEnabled = false
            addBtn.backgroundColor = .clear
            addBtn.setTitleColor(UIColor.eec.rgb(0x666666), for: .normal)
            if model.flag == .agree {
                addBtn.setTitle(LocalizedString("Agreed"), for: .normal)
            } else {
                addBtn.setTitle(LocalizedString("Rejected"), for: .normal)
            }
        }
    }
    
    @IBAction func addAction() {
        var api = ApiFriendAddFriendResponse()
        api.param.uid = model.userInfo.uid
        api.param.flag = .agree
        _ = api.request(showLoading: true)
            .subscribe(onSuccess: { [unowned self] resp in
                self.model.flag = api.param.flag
                self.refresh()
            })
    }
    
}
