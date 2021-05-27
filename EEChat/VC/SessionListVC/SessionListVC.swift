//
//  SessionListVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import UIKit
import RxSwift
import RxCocoa
import OpenIM

class SessionListVC: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSession()
    }
    
    private var array: [Session] = []
    
    private func bindAction() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SessionListCell.eec.nib(), forCellReuseIdentifier: "cell")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSession),
                                               name: OpenIMManager.updateSessionNotification, object: nil)
    }
    
    @objc func updateSession() {
        let array = OpenIMManager.shared.getSessions().sorted { (session0, session1) -> Bool in
            if session0.isTop, session1.isTop {
                return session0.date > session1.date
            }
            return session0.isTop || session0.date > session1.date
        }

        let uids = array.map{ $0.session.id }.filter{ OpenIMManager.shared.getUser(uid: $0) == nil }
        if !uids.isEmpty {
            OpenIMManager.shared.update(uids: uids) { [weak self] in
                self?.tableView.reloadData()
            }
        }

        self.array = array
        self.tableView.reloadData()
    }

}

extension SessionListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = array[indexPath.row]
        let title = model.isTop ? "取消置顶" : "置顶"
        let top = UIContextualAction(style: .normal, title: title)
        { (action, view, completionHandler) in
            let isTop = !model.isTop
            var newRow: Int = {
                if isTop {
                    return 0
                }
                return self.array.firstIndex { !$0.isTop } ?? self.array.count - 1
            }()
            model.isTop = isTop
            OpenIMManager.shared.update(session: model)
            self.tableView.performBatchUpdates {
                if indexPath.row < newRow {
                    newRow -= 1
                }
                
                self.array.remove(at: indexPath.row)
                self.array.insert(model, at: newRow)
                self.tableView.moveRow(at: indexPath, to: IndexPath(row: newRow, section: 0))
            }
        }
        top.backgroundColor = UIColor.eec.rgb(0x1B72EC)

        let delete = UIContextualAction(style: .destructive, title: "删除")
        { (action, view, completionHandler) in
            OpenIMManager.shared.delete(session: model)
            self.tableView.performBatchUpdates {
                self.array.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        delete.backgroundColor = UIColor.eec.rgb(0x7CBAFF)

        if model.unread == 0 {
            return UISwipeActionsConfiguration(actions: [delete, top])
        }

        let read = UIContextualAction(style: .destructive, title: "标为已读")
        { (action, view, completionHandler) in
            model.unread = 0
            OpenIMManager.shared.update(session: model)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        read.backgroundColor = UIColor.eec.rgb(0xFFD576)

        return UISwipeActionsConfiguration(actions: [read, delete, top])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = array[indexPath.row]
        ChatVC.show(model.session)
        PushManager.shared.clear(model.session)
    }
    
}

extension SessionListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SessionListCell
        cell.model = array[indexPath.row]
        return cell
    }
}
