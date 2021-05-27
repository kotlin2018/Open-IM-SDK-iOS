//
//  FriendSettingVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/25.
//

import UIKit
import OpenIM

class FriendSettingVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        assert(param is String)
        var api = ApiFriendSearch()
        api.param.uid = param as! String
        _ = api.request(showLoading: true)
            .map(type: ApiFriendSearch.Model.self)
            .subscribe(onSuccess: { model in
                super.show(param: model, callback: callback)
            })
    }

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var topButton: UIButton!
    @IBOutlet var blacklistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI()
    }
    
    private lazy var model: ApiFriendSearch.Model = {
        assert(param is ApiFriendSearch.Model)
        return param as! ApiFriendSearch.Model
    }()
    
    private func refreshUI() {
        let userInfo = model.userInfo
        avatarImageView.setImage(with: userInfo.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = userInfo.getName()
        blacklistButton.isSelected = model.isInBlackList
        
        if let session = OpenIMManager.shared.getSession(.p2p(userInfo.uid)) {
            topButton.isSelected = session.isTop
        } else {
            topButton.isSelected = false
        }
    }
    
    // MARK: - Action
    
    @IBAction func historyAction() {
        ChatHistoryVC.show(param: SessionType.p2p(model.userInfo.uid))
    }
    
    @IBAction func remarkAction() {
        UIAlertController.show(title: LocalizedString("Modify the remark"),
                               message: nil,
                               text: model.userInfo.comment,
                               placeholder: LocalizedString("Please enter remarks"))
        { (text) in
            var api = ApiFriendSetComment()
            api.param.uid = self.model.userInfo.uid
            api.param.comment = text
            api.request(showLoading: true)
                .subscribe(onSuccess: { _ in
                    MessageModule.showMessage(text: LocalizedString("Modify the success"))
                    self.model.userInfo.comment = text
                    self.refreshUI()
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    @IBAction func topAction(_ sender: UIButton) {
        let userInfo = model.userInfo
        let isTop = !sender.isSelected
        if let session = OpenIMManager.shared.getSession(.p2p(userInfo.uid)) {
            session.isTop = isTop
        } else {
            let session = Session()
            session.session = .p2p(userInfo.uid)
            session.isTop = true
            session.date = Date().timeIntervalSince1970
            OpenIMManager.shared.update(session: session)
        }
        sender.isSelected = isTop
    }
    
    @IBAction func blacklistTop(_ sender: UIButton) {
        let uid = model.userInfo.uid
        let isInBlackList = sender.isSelected
        let apiResult: ApiResult = {
            if isInBlackList {
                var api = ApiFriendRemoveBlacklist()
                api.param.uid = uid
                return api.request(showLoading: true)
            }
            var api = ApiFriendAddBlacklist()
            api.param.uid = uid
            return api.request(showLoading: true)
        }()
        
        apiResult
            .subscribe(onSuccess: { _ in
                let text = isInBlackList ? LocalizedString("Remove blacklist successfully") : LocalizedString("Add blacklist successfully")
                MessageModule.showMessage(text: text)
                self.model.isInBlackList = !isInBlackList
                self.refreshUI()
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func clearHistoryAction() {
        UIAlertController.show(title: LocalizedString("Clear the chat history?"),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                let uid = self.model.userInfo.uid
                OpenIMManager.shared.deleteAllMessage(.p2p(uid))
            }
        }
    }
    
    @IBAction func delFriendAction() {
        UIAlertController.show(title: LocalizedString("Remove friends?"),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                self.delFriend()
            }
        }
    }
    
    private func delFriend() {
        let uid = model.userInfo.uid
        var api = ApiFriendRemoveFriend()
        api.param.uid = uid
        api.request(showLoading: true)
            .subscribe(onSuccess: { _ in
                NavigationModule.shared.pop(popCount: 2)
                OpenIMManager.shared.deleteSession(.p2p(uid))
            })
            .disposed(by: disposeBag)
    }
}
