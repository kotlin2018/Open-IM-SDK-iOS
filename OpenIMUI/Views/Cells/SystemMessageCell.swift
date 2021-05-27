//
//  SystemMessageCell.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/27.
//

import UIKit

public class SystemMessageCell: MessageCollectionViewCell {
    
    lazy var containerView: UIView = {
        translatesAutoresizingMaskIntoConstraints = false
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            view.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        return view
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        return label
    }()
    
    public override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError()
        }
        
        textLabel.font = displayDelegate.systemTextFont(for: message, at: indexPath, in: messagesCollectionView)
        textLabel.textColor = displayDelegate.systemTextColor(for: message, at: indexPath, in: messagesCollectionView)
        
        switch message.content {
        case .system(_, let item):
            textLabel.text = item.text
        default:
            fatalError()
        }
    }
    
}
