//
//  BlacklistVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/27.
//

import UIKit
import RxCocoa
import OpenIM

class BlacklistVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        _ = ApiFriendGetBlacklist().request(showLoading: true)
            .map(type: [ApiFriendGetBlacklist.Model].self)
            .subscribe(onSuccess: { array in
                super.show(param: array, callback: callback)
            })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    @IBOutlet var tableView: UITableView!
    
    private let relay = BehaviorRelay<[ApiFriendGetBlacklist.Model]>(value: [])
    private func bindAction() {
        assert(param is [ApiFriendGetBlacklist.Model])
        let array = param as! [ApiFriendGetBlacklist.Model]
        relay.accept(array)
        
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell",
                                         cellType: BlacklistCell.self))
            { [unowned self] row, model, cell in
                cell.model = model
                cell.removeCallback = {
                    self.removeAction(model: model, row: row)
                }
            }
            .disposed(by: disposeBag)
    }

    func removeAction(model: ApiFriendGetBlacklist.Model, row: Int) {
        var api = ApiFriendRemoveBlacklist()
        api.param.uid = model.uid
        api.request(showLoading: true)
            .subscribe(onSuccess: { [unowned self] _ in
                var array = self.relay.value
                array.remove(at: row)
                self.relay.accept(array)
            })
            .disposed(by: disposeBag)
        
    }
    
}
