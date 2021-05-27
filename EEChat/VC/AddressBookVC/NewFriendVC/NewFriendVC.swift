//
//  NewFriendVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/21.
//

import UIKit
import RxCocoa
import OpenIM

class NewFriendVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        _ = ApiFriendGetApplyList().request(showLoading: true)
            .map(type: [ApiFriendGetApplyList.Model].self)
            .subscribe(onSuccess: { array in
                super.show(param: array, callback: callback)
            })
    }

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    private func bindAction() {
        assert(param is [ApiFriendGetApplyList.Model])
        let array = param as! [ApiFriendGetApplyList.Model]
        
        let relay = BehaviorRelay<[ApiFriendGetApplyList.Model]>(value: array)
        
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: NewFriendCell.self))
            { _, model, cell in
                cell.model = model
            }
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(ApiFriendGetApplyList.Model.self)
            .subscribe(onNext: { model in
                if model.flag == .agree {
                    
                }
            })
            .disposed(by: disposeBag)
    }

}
