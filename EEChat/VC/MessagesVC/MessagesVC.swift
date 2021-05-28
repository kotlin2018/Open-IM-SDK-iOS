//
//  MessagesVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/19.
//

import UIKit
import OpenIM
import OpenIMUI
import RxSwift
import Photos
import AVFoundation

open class MessagesVC: MessagesViewController {
    
    open class func vc(_ sessionType: SessionType) -> Self {
        let vc = Self.init()
        vc.sessionType = sessionType
        return vc
    }
    
    public let disposeBag = DisposeBag()
    
    private lazy var audioController = BasicAudioController(messageCollectionView: self.messagesCollectionView)
    
    private(set) var sessionType = SessionType.p2p("")
    private(set) var messages: [MessageType] = []
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.refreshControl = refreshControl
        
        self.messages = loadDBMessage()
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(animated: false)
        }
        
        OpenIMManager.shared.addListener(sessionType, listener: self)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
        requestInfo()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let message = messages.last {
            OpenIMManager.shared.updateSession(message)
        }
    }
    
    deinit {
        OpenIMManager.shared.removeListener(sessionType, listener: self)
    }
    
    private func requestInfo() {
        switch sessionType {
        case .p2p(let uid):
            let mineUid = OpenIMManager.shared.model.uid
            OpenIMManager.shared.update(uids: [mineUid, uid]) { [weak self] in
                guard let self = self else { return }
                self.refreshUI()
                self.messagesCollectionView.reloadData()
            }
        case .group(_):
            break
        }
    }
    
    private func refreshUI() {
        switch sessionType {
        case .p2p(let uid):
            if let user = OpenIMManager.shared.getUser(uid: uid) {
                title = user.getName()
            }
        case .group(_):
            fatalError()
        }
    }
    
    private func insert(row: Int, messages: [Message], isScroll: Bool) {
        let messages = preprocess(messages: messages)
        messagesCollectionView.performBatchUpdates {
            let sections = (0..<messages.count).map { row + $0 }
            self.messages.insert(contentsOf: messages, at: row)
            self.messagesCollectionView.insertSections(IndexSet(sections))
        } completion: { (_) in
            if isScroll {
                self.messagesCollectionView.scrollToLastItem()
            }
        }
    }
    
    private func append(_ messages: [Message], isScroll: Bool = true) {
        menuWindow.hide()
        let row = self.messages.count
        insert(row: row, messages: messages, isScroll: isScroll)
    }
    
    private func preprocess(messages: [Message]) -> [Message] {
        return messages.filter{ $0.isDisplay && !self.messages.contains($0) }
    }
    
    private func loadDBMessage(count: Int = 50) -> [Message] {
        let msgId = messages.first?.messageId ?? ""
        let messages = OpenIMManager.shared.fetch(sessionType, count: count, offset: msgId)
        if messages.count < count {
            messagesCollectionView.refreshControl = nil
        }
        return preprocess(messages: messages)
    }
    
    @objc
    private func loadMoreMessages() {
        let messages = loadDBMessage()
        self.messages.insert(contentsOf: messages, at: 0)
        self.messagesCollectionView.reloadDataAndKeepOffset()
        self.refreshControl.endRefreshing()
    }
    
    private func updateBlock() -> (Message) -> Void {
        return { [weak self] message in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let indexPath = self.messagesCollectionView.indexPathsForVisibleItems.first { indexPath in
                    return self.messages[indexPath.section] == message
                }
                if let indexPath = indexPath {
                    self.messagesCollectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
    
    // MARK: - Override
    
    private var menuWindow = MenuWindow()
    
    open override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MessageContentCell else {
            return false
        }
        
        let message = messages[indexPath.section]
        let deleteItem = MenuItem(title: LocalizedString("Delete"),
                                  image: UIImage(named: "chat_popup_icon_delete"))
        {
            UIAlertController.show(title: LocalizedString("Delete?"),
                                   message: nil,
                                   buttons: [LocalizedString("Yes")],
                                   cancel: LocalizedString("No"))
            { (index) in
                if index == 0 {
                    return
                }
                
                OpenIMManager.shared.delete([message])
                
                collectionView.performBatchUpdates {
                    self.messages.remove(at: indexPath.section)
                    collectionView.deleteSections(IndexSet([indexPath.section]))
                }
                
                if indexPath.row == self.messages.count {
                    if let message = self.messages.last {
                        OpenIMManager.shared.updateSession(message)
                    } else {
                        OpenIMManager.shared.updateSession(message, isDelete: false)
                    }
                }
            }
        }
        
        let forwardItem = MenuItem(title: LocalizedString("Forward"),
                                   image: UIImage(named: "chat_popup_icon_forward"))
        {
            LocalSearchUserVC.show(param: message)
        }
        
        var items: [MenuItem] = [deleteItem, forwardItem]
        
        if case let ContentType.text(text) = message.content {
            let copyItem = MenuItem(title: LocalizedString("Copy"),
                                    image: UIImage(named: "chat_popup_icon_copy"))
            {
                UIPasteboard.general.string = text
                MessageModule.showMessage(text: LocalizedString("Copied"))
            }
            items = [copyItem, deleteItem, forwardItem]
        }
        
        menuWindow.show(targetView: cell.messageContainerView, items: items)
        return true
    }
    
    open override func inputBarView(_ inputBarView: InputBarView, didSend text: String) {
        let message = OpenIMManager.shared.send(sessionType, content: .text(text), callback: updateBlock())
        append([message])
    }
    
    open override func inputBarRecordView(_ inputBarRecordView: InputBarRecordView, finish url: URL) {
        let player = try? AVAudioPlayer(contentsOf: url)
        let duration = player?.duration ?? 0.0
        if duration < 1 {
            MessageModule.showMessage(text: LocalizedString("The recording time is too short"))
            return
        }
        
        self.upload(files: [url]) { (paths) in
            let item = AudioItem(url: URL(string: paths.first!), duration: Int(ceil(duration)))
            let message = OpenIMManager.shared.send(self.sessionType, content: .audio(item), callback: self.updateBlock())
            self.append([message])
        }
    }
    
    private func upload(files: [Any], callback: @escaping ([String]) -> Void) {
        let prefix = OpenIMManager.shared.model.uid
        QCloudModule.shared.upload(prefix: prefix, files: files)
            .subscribe(onSuccess: { paths in
                callback(paths)
            })
            .disposed(by: self.disposeBag)
    }
    
    open override func inputBarMoreView(_ inputBarMoreView: InputBarMoreView, didSelect index: Int) {
        switch index {
        case 0:
            PhotoModule.shared.showCamera { [unowned self] (image) in
                self.upload(files: [image]) { (paths) in
                    let url = paths.first!
                    let item = MediaItem(url: URL(string: url),
                                         thumbnail: URL(string: QCloudModule.shared.thumbnail(url: url)),
                                         width: Int(image.size.width),
                                         height: Int(image.size.height))
                    let message = OpenIMManager.shared.send(self.sessionType, content: .image(item), callback: updateBlock())
                    self.append([message])
                }
            }
        case 1:
            PhotoModule.shared.showPicker(type: .image, selected: [], maxCount: 9, allowTake: false)
            { [unowned self] (images, assets) in
                self.upload(files: assets) { (paths) in
                    var messages: [Message] = []
                    for (index, url) in paths.enumerated() {
                        let asset = assets[index] as! PHAsset
                        let item = MediaItem(url: URL(string: url),
                                             thumbnail: URL(string: QCloudModule.shared.thumbnail(url: url)),
                                             width: Int(asset.pixelWidth),
                                             height: Int(asset.pixelHeight))
                        let message = OpenIMManager.shared.send(self.sessionType, content: .image(item), callback: updateBlock())
                        messages.append(message)
                    }
                    
                    self.append(messages)
                }
            }
        default:
            fatalError()
        }
    }

}

extension MessagesVC: MessagesDataSource {
    public func currentSenderID() -> String {
        return OpenIMManager.shared.model.uid
    }
    
    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    public func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        fatalError()
    }
    
    public func nameLabelAttributedText(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> NSAttributedString? {
        return nil
    }
    
}

extension MessagesVC: MessagesLayoutDelegate {
    
    public func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        let message = messages[section]
        if section > 0 {
            let prevMessage = messages[section - 1]
            if message.sendTime - prevMessage.sendTime < 5 * 60 {
                return .zero
            }
        }
        
        let itemWidth = messagesCollectionView.messagesCollectionViewFlowLayout.itemWidth
        return CGSize(width: itemWidth, height: 30)
    }
    
    public func nameLabelIsHidden(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        switch sessionType {
        case .p2p:
            return true
        case .group:
            return isFromCurrentSender(message: message)
        }
    }
    
}

extension MessagesVC: MessagesDisplayDelegate {
    
    public func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        let message = messages[indexPath.section]
        
        let view = messagesCollectionView.dequeueReusableHeaderView(MessageReusableDateView.self, for: indexPath)
        
        view.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        return view
    }
    
    public func configureAvatarView(_ avatarView: MessageImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.layer.cornerRadius = avatarView.bounds.height * 0.5
        avatarView.image = UIImage(named: "icon_default_avatar")
        if let userInfo = OpenIMManager.shared.getUser(uid: message.sendID) {
            avatarView.setImage(with: userInfo.icon,
                                placeholder: avatarView.image)
        }
    }
    
    public func configureAccessoryView(_ accessoryView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        accessoryView.isHidden = true
        if message.isFromCurrentSender {
            if message.status == .failure {
                accessoryView.isHidden = false
                accessoryView.image = ImageCache.named("openim_icon_send_error")
            }
        } else {
            if case ContentType.audio = message.content,
               message.status != .clicked {
                accessoryView.isHidden = false
                accessoryView.image = ImageCache.named("openim_icon_voice_unclicked")
            }
        }
    }
    
    public func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message)
    }
    
}

extension MessagesVC: MessageCellDelegate {
    public func didTapBackground(in cell: MessageCollectionViewCell) {
        
    }
    
    public func didTapName(in cell: MessageCollectionViewCell) {
        
    }
    
    public func didTapAvatar(in cell: MessageCollectionViewCell) {
        
    }
    
    public func didTapMessage(in cell: MessageCollectionViewCell) {
        
    }
    
    public func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                return
        }
        
        if message.isFromCurrentSender {
            OpenIMManager.shared.send(message, callback: updateBlock())
            messagesCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    public func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                return
        }
        
        switch message.content {
        case .image(let item):
            if let url = item.url  {
                PhotoModule.shared.showPhoto([url])
            }
        case .video(_):
            break
        default:
            fatalError()
        }
    }
    
    public func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                return
        }
        
        audioController.playOrStopSound(for: message, in: cell)
        if message.status != .clicked {
            message.status = .clicked
            OpenIMManager.shared.update(message: message)
            messagesCollectionView.reloadItems(at: [indexPath])
        }
    }
}

extension MessagesVC: OpenIMHandleMessageDelegate {
    public func handleMessage(_ messages: [Message]) {
        append(messages)
    }
}
