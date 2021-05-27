//
//  MessageReusableDateView.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/27.
//

import UIKit

open class MessageReusableDateView: MessageReusableView {
    
    open lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        return view
    }()
    
    open lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        return label
    }()
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = ""
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError()
        }
        
        dateLabel.font = displayDelegate.systemTextFont(for: message, at: indexPath, in: messagesCollectionView)
        dateLabel.textColor = displayDelegate.systemTextColor(for: message, at: indexPath, in: messagesCollectionView)
        
        dateLabel.text = OpenIMDateFormatter.shared.format(message.sendTime)
    }
}
