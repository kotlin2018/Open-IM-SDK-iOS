//
//  ChatMediaHistoryVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/26.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import OpenIM

class ChatMediaHistoryVC: BaseViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateBarButton()
        bindAction()
        loadDB()
    }
    
    private lazy var sessionType: SessionType = {
        assert(param is SessionType)
        return param as! SessionType
    }()
    
    private var selectIndexPath: Set<IndexPath> = []
    private let relay = BehaviorRelay<[SectionModel<String, Message>]>(value: [])
    private func bindAction() {
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 0, height: 50)
        let width = floor(UIScreen.main.bounds.width / 4)
        layout.itemSize = CGSize(width: width, height: width)
        
        collectionView.register(ChatMediaHistoryCell.eec.nib(), forCellWithReuseIdentifier: "cell")
        collectionView.register(ChatMediaHistoryReusableView.eec.nib(),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "header")
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Message>>(
            configureCell: { [unowned self] _, cv, indexPath, element in
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChatMediaHistoryCell
                cell.selectBtn.isHidden = !self.collectionView.allowsMultipleSelection
                cell.selectBtn.isSelected = self.selectIndexPath.contains(indexPath)
                cell.model = element
                cell.selectCallback = {
                    if self.selectIndexPath.contains(indexPath) {
                        self.selectIndexPath.remove(indexPath)
                        return false
                    }
                    if self.selectIndexPath.count == 9 {
                        let text = String(format: LocalizedString("Select a maximum of %@ photos"), self.selectIndexPath.count)
                        MessageModule.showMessage(text: text)
                        return false
                    }
                    self.selectIndexPath.insert(indexPath)
                    return true
                }
                
                return cell
            },
            configureSupplementaryView: { [unowned self] _, cv, kind, indexPath in
                let view = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
                    as! ChatMediaHistoryReusableView
                
                view.titleLabel.text = self.relay.value[indexPath.section].model
                
                return view
            }
        )
        
        relay
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(Message.self)
            .subscribe(onNext: { model in
                switch model.content {
                case .image(let item), .video(let item):
                    if let url = item.url {
                        PhotoModule.shared.showPhoto([url])
                    }
                default:
                    fatalError()
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    private func loadDB() {
        let nowComponent = NSCalendar.current.dateComponents([.year, .month, .weekOfYear], from: Date())
        let dateFormatter = DateFormatter()
        
        let array = OpenIMManager.shared.fetch(sessionType, type: .image)
            .reduce(into: [String: [Message]]()) { (result, message) in
                let date = Date(timeIntervalSince1970: message.sendTime)
                let component = NSCalendar.current.dateComponents([.year, .month, .weekOfYear], from: date)
                let key: String = {
                    if nowComponent.year == component.year {
                        if nowComponent.weekOfYear == component.weekOfYear {
                            return LocalizedString("This week")
                        }
                        if nowComponent.month == component.month {
                            return LocalizedString("This month")
                        }
                        return "YYYY/MM"
                    }
                    return dateFormatter.string(from: date)
                }()

                if result[key] == nil {
                    result[key] = []
                }
                result[key]?.append(message)
            }
            .map { (key: String, value: [Message]) -> SectionModel<String, Message> in
                return SectionModel(model: key, items: value)
            }

        relay.accept(array)
    }
    
    private lazy var choiceBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        btn.setTitleColor(UIColor.eec.rgb(0x333333), for: .normal)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(choiceAction))
        btn.addGestureRecognizer(gestureRecognizer)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
        return btn
    }()
    
    //
    private func updateBarButton() {
        let allowsMultipleSelection = collectionView.allowsMultipleSelection
        let title = allowsMultipleSelection ? " \(LocalizedString("Cancel")) " : " \(LocalizedString("Select")) "
        choiceBtn.setTitle(title, for: .normal)
        
        bottomView.eec_collapsed = !allowsMultipleSelection
        
        collectionView.reloadData()
        selectIndexPath.removeAll()
    }
    
    // MARK: - Action
    @objc
    func choiceAction() {
        collectionView.allowsMultipleSelection = !collectionView.allowsMultipleSelection
        updateBarButton()
    }
    
    private var selectMessages: [Message] {
        return selectIndexPath.map{ relay.value[$0.section].items[$0.row] }
    }
    
    @IBAction func forwardAction() {
        let messages = selectMessages
        LocalSearchUserVC.show(param: messages)
    }
    
    @IBAction func downloadAction() {
        let urls = selectMessages.compactMap { (message) -> URL? in
            switch message.content {
            case .image(let item), .video(let item):
                return item.url
            default:
                return nil
            }
        }
        
        PhotoModule.shared.batchDownloader(urls: urls) { images in
            images.forEach { (image) in
                PhotoModule.shared.writeToSavedPhotosAlbum(image: image)
            }
            MessageModule.shared.showMessage(text: LocalizedString("Downloaded"))
        }
    }
    
    @IBAction func deleteAction() {
        UIAlertController.show(title: LocalizedString("Delete?"),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                self.delete()
            }
        }
    }
    
    private func delete() {
        let messages = selectMessages
        
        let indexPaths = Array(selectIndexPath).sorted { (indexPath0, indexPath1) -> Bool in
            if indexPath0.section == indexPath1.section {
                return indexPath0.row > indexPath1.row
            }
            return indexPath0.section > indexPath1.section
        }
        
        var array = self.relay.value
        indexPaths.forEach { (indexPath) in
            array[indexPath.section].items.remove(at: indexPath.row)
        }
        
        relay.accept(array.filter{ !$0.items.isEmpty })
        
        OpenIMManager.shared.delete(messages)
    }
}


