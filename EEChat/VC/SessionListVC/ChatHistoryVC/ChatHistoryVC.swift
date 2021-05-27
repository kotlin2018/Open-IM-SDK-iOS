//
//  ChatHistoryVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/25.
//

import UIKit
import RxSwift
import RxCocoa
import OpenIM

class ChatHistoryVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        let vc = self.vc(param: param, callback: callback)
        NavigationModule.shared.presentCustom(vc)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        fd_prefersNavigationBarHidden = true
        
        fetchUserInfo()
        bindAction()
    }
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableHeaderView: UIView!
    @IBOutlet var tableFooterView: UIView!
    @IBOutlet var notFoundLabel: UILabel!
    
    private lazy var sessionType: SessionType = {
        assert(param is SessionType)
        return param as! SessionType
    }()
    
    private let relay = BehaviorRelay<[Message]>(value: [])
    private func bindAction() {
        
        textField.rx.text
            .debounce(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
            .startWith("")
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] text in
                self.fetch(text: text ?? "")
            })
            .disposed(by: disposeBag)
        
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: ChatHistoryCell.self))
            { [unowned self] _, model, cell in
                cell.config(model: model, info: self.userInfo, key: self.textField.text ?? "")
            }
            .disposed(by: disposeBag)
    }
    
    private var userInfo: UserInfo?
    
    private func fetchUserInfo() {
        if let value = OpenIMManager.shared.getUser(uid: sessionType.id) {
            userInfo = value
            self.tableView.reloadData()
        } else {
            OpenIMManager.shared.update(uids: [sessionType.id]) { [weak self] in
                self?.fetchUserInfo()
            }
        }
    }
    
    private func fetch(text: String) {
        if text != "" {
            tableView.tableHeaderView = nil
            let array = OpenIMManager.shared.fetch(sessionType, type: .text, key: text)
            relay.accept(array)
            if array.isEmpty {
                tableView.tableFooterView = tableFooterView

                let str = String(format: LocalizedString("\"%@\" not found"), text)
                let attributedText = NSMutableAttributedString(string: str)
                attributedText.addAttributes([.foregroundColor : UIColor.eec.rgb(0x1B72EC)],
                                             range: NSRange(location: 5, length: text.count))
                notFoundLabel.attributedText = attributedText
            } else {
                tableView.tableFooterView = nil
                notFoundLabel.attributedText = nil
            }
        } else {
            relay.accept([])
            tableView.tableHeaderView = tableHeaderView
            tableView.tableFooterView = nil
        }
    }

    // MARK: - Action
    @IBAction func closeAction() {
        NavigationModule.shared.dismiss(self)
    }
    
    @IBAction func imageAction() {
        ChatMediaHistoryVC.show(param: sessionType)
    }
    
    @IBAction func videoAction() {
        
    }
    
}
