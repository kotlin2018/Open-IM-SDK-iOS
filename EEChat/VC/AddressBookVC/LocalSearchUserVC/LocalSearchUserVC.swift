//
//  LocalSearchUserVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/22.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import OpenIM

class LocalSearchUserVC: BaseViewController {

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    @IBOutlet var textField: UITextField!
    private func bindAction() {
        switch param {
        case nil:
            title = LocalizedString("Search")
            tableView.rx.modelSelected(UserInfo.self)
                .subscribe(onNext: { model in
                    SearchUserDetailsVC.show(param: model.uid)
                })
                .disposed(by: disposeBag)
        case let message as Message:
            title = LocalizedString("Select")
            tableView.rx.modelSelected(UserInfo.self)
                .subscribe(onNext: { [unowned self] model in
                    self.forward(model: model, messages: [message])
                })
                .disposed(by: disposeBag)
        case let messages as [Message]:
            title = LocalizedString("Select")
            tableView.rx.modelSelected(UserInfo.self)
                .subscribe(onNext: { [unowned self] model in
                    self.forward(model: model, messages: messages)
                })
                .disposed(by: disposeBag)
        default:
            fatalError()
        }
        
        let relay = BehaviorRelay<[SectionModel<String, UserInfo>]>(value: [])
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, UserInfo>>(
            configureCell: { _, tv, _, element in
                let cell = tv.dequeueReusableCell(withIdentifier: "cell")! as! LocalSearchUserCell
                cell.model = element

                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                dataSource[sectionIndex].model
            },
            canMoveRowAtIndexPath: { _, _ in
                return false
            }
        )
        
        relay
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        let recent = OpenIMManager.shared.getSessions()
            .compactMap{ OpenIMManager.shared.getUser(uid: $0.session.id) }
        
        textField.rx.text
            .skip(1)
            .debounce(DispatchTimeInterval.microseconds(500), scheduler: MainScheduler.instance)
            .startWith("")
            .distinctUntilChanged()
            .subscribe(onNext: { text in
                let friends: [UserInfo] = {
                    if let text = text, text != "" {
                        return OpenIMManager.shared.fetchFriends(text)
                    }
                    return []
                }()
                var array = [SectionModel(model: "", items: friends)]
                if recent.count > 0 {
                    array.append(SectionModel(model: LocalizedString("Recent Session"), items: recent))
                }
                relay.accept(array)
            })
            .disposed(by: disposeBag)
    }
    
    private func forward(model: UserInfo, messages: [Message]) {
        UIAlertController.show(title: String(format: LocalizedString("Send to %@?"), model.getName()),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                for message in messages {
                    OpenIMManager.shared.send(.p2p(model.uid), content: message.content)
                }
                MessageModule.showMessage(text: LocalizedString("Sent"))
            }
        }
    }
}
