//
//  MessagesViewController.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/8.
//

import UIKit

open class MessagesViewController: UIViewController,
                                   UICollectionViewDelegateFlowLayout,
                                   UICollectionViewDelegate,
                                   UICollectionViewDataSource,
                                   InputBarViewDelegate,
                                   InputBarMoreViewDelegate {
    
    open private(set) lazy var messagesCollectionView: MessagesCollectionView = {
        let messagesCollectionView = MessagesCollectionView()
        messagesCollectionView.keyboardDismissMode = .interactive
        messagesCollectionView.alwaysBounceVertical = true
        messagesCollectionView.backgroundColor = .white
        messagesCollectionView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 13.0, *) {
            messagesCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        messagesCollectionView.delegate = self
        messagesCollectionView.dataSource = self
        messagesCollectionView.resignBlock = { [weak self] in
            self?.resignInputBar()
        }
        
        return messagesCollectionView
    }()
    
    open lazy var inputBarAccessoryView: InputBarAccessoryView = {
        let inputBarAccessoryView = InputBarAccessoryView()
        inputBarAccessoryView.inputBarView.delegate = self
        inputBarAccessoryView.inputBarMoreView.delegate = self
        return inputBarAccessoryView
    }()
    
    internal var keyboardIsShow = false
    
    internal var messageCollectionViewBottomInset: CGFloat = 0 {
        didSet {
            messagesCollectionView.contentInset.bottom = messageCollectionViewBottomInset
            messagesCollectionView.scrollIndicatorInsets.bottom = messageCollectionViewBottomInset
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaults()
        setupSubviews()
        addObserver()
    }
    
    private var isFirstLayout: Bool = true
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isFirstLayout {
            addKeyboardObservers()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }
    
    open override func viewDidLayoutSubviews() {
        if isFirstLayout {
            defer { isFirstLayout = false }
            addKeyboardObservers()
            messageCollectionViewBottomInset = requiredScrollViewBottomInset()
        }
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        messageCollectionViewBottomInset = requiredScrollViewBottomInset()
    }
    
    // MARK: - Methods [Private]

    private func setupDefaults() {
        extendedLayoutIncludesOpaqueBars = false
        view.backgroundColor = .white
    }
    
    private func setupSubviews() {
        do {
            view.addSubview(messagesCollectionView)
            messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
            
            let top = messagesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            let bottom = messagesCollectionView.bottomAnchor.constraint(equalTo:  view.bottomAnchor)
            let leading = messagesCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            let trailing = messagesCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            NSLayoutConstraint.activate([top, bottom, trailing, leading])
        }
    }
    
    private func addObserver() {
        
    }
    
    // MARK: - Methods
    
    open func resignInputBar() {
        inputBarAccessoryView.resignInputBar()
    }
    
    
    // MARK: - Override
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    open override var inputAccessoryView: UIView? {
        return inputBarAccessoryView
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let messagesFlowLayout = collectionViewLayout as? MessagesCollectionViewFlowLayout else { return .zero }
        return messagesFlowLayout.sizeForItem(at: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }
        guard let layoutDelegate = messagesCollectionView.messagesLayoutDelegate else {
            fatalError()
        }
        
        return layoutDelegate.headerViewSize(for: section, in: messagesCollectionView)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }
        guard let layoutDelegate = messagesCollectionView.messagesLayoutDelegate else {
            fatalError()
        }
        
        return layoutDelegate.footerViewSize(for: section, in: messagesCollectionView)
    }
    
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resignInputBar()
    }
    
    // MARK: - UICollectionViewDataSource
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let collectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }
        let sections = collectionView.messagesDataSource?.numberOfSections(in: collectionView) ?? 0
        return sections
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }
        return collectionView.messagesDataSource?.numberOfItems(inSection: section, in: collectionView) ?? 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError()
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        let cell: MessageCollectionViewCell
        switch message.content {
        case .text, .unknown:
            cell = messagesCollectionView.dequeueReusableCell(TextMessageCell.self, for: indexPath)
        case .image, .video:
            cell = messagesCollectionView.dequeueReusableCell(MediaMessageCell.self, for: indexPath)
        case .audio:
            cell = messagesCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
        case .system(_, _):
            cell = messagesCollectionView.dequeueReusableCell(SystemMessageCell.self, for: indexPath)
        }
        
        cell.configure(with: message, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError()
        }

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError()
        }

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return displayDelegate.messageHeaderView(for: indexPath, in: messagesCollectionView)
        case UICollectionView.elementKindSectionFooter:
            return displayDelegate.messageFooterView(for: indexPath, in: messagesCollectionView)
        default:
            fatalError()
        }
    }
    
    // MARK: - InputBarViewDelegate
    
    open func inputBarView(_ inputBarView: InputBarView, didSend text: String) {
        
    }

    open func inputBarRecordView(_ inputBarRecordView: InputBarRecordView, finish url: URL) {
        
    }
    
    // MARK: - InputBarMoreViewDelegate
    open func inputBarMoreView(_ inputBarMoreView: InputBarMoreView, didSelect index: Int) {
        
    }
    
}
