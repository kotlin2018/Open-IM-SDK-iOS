//
//  SearchUserDetailsVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/19.
//

import UIKit
import OpenIM

class SearchUserDetailsVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        switch param {
        case let id as String:
            var api = ApiFriendSearch()
            api.param.uid = id
            _ = api.request(showLoading: true)
                .map(type: ApiFriendSearch.Model.self)
                .subscribe(onSuccess: { model in
                    super.show(param: model, callback: callback)
                })
        case is ApiFriendSearch.Model:
            super.show(param: param, callback: callback)
        default:
            fatalError()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        refreshUI()
        
        OpenIMManager.shared.addListener(.p2p(model.userInfo.uid), listener: self)
    }
    
    deinit {
        OpenIMManager.shared.removeListener(.p2p(model.userInfo.uid), listener: self)
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accountLabel: UILabel!
    
    lazy var model: ApiFriendSearch.Model = {
        assert(param is ApiFriendSearch.Model)
        return param as! ApiFriendSearch.Model
    }()
    
    private func bindAction() {
        let layer = contentView.superview!.layer
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.14).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        
        accountLabel.rx.tapGesture()
            .when(.ended)
            .subscribe(onNext: { [unowned self] _ in
                UIPasteboard.general.string = self.model.userInfo.uid
                MessageModule.showMessage(text: LocalizedString("The account has been copied!"))
            })
            .disposed(by: disposeBag)
    }
    
    private func refreshUI() {
        let userInfo = model.userInfo
        avatarImageView.setImage(with: userInfo.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = userInfo.getName()
        accountLabel.text = LocalizedString("Account:") + userInfo.uid
        
        if userInfo.uid == AccountManager.shared.model.userInfo.uid {
            button.eec_collapsed = true
            return
        }
        
        button.eec_collapsed = false
        if model.isFriend {
            button.setTitle(" " + LocalizedString("Chat"), for: .normal)
            button.setImage(UIImage(named: "friend_detail_icon_msg"), for: .normal)
        } else {
            button.setTitle(" " + LocalizedString("Add friend"), for: .normal)
            button.setImage(UIImage(named: "friend_detail_icon_add"), for: .normal)
        }
    }
    
    @IBOutlet var button: UIButton!
    @IBAction func btnAction() {
        if model.isFriend {
            ChatVC.show(.p2p(model.userInfo.uid))
            return
        }
        
        var api = ApiFriendAddFriend()
        api.param.uid = model.userInfo.uid
        api.request(showLoading: true)
            .subscribe(onSuccess: { _ in
                MessageModule.showMessage(text: LocalizedString("Sent friend request"))
            })
            .disposed(by: disposeBag)
    }
}

extension SearchUserDetailsVC: OpenIMHandleMessageDelegate {
    func handleSystemMessage(_ messages: [Message]) {
        messages.forEach { message in
            if case let ContentType.system(op, _) = message.content {
                if op == .agreedAddFriend {
                    self.model.isFriend = true
                    refreshUI()
                }
            }
        }
    }
}
