//
//  MediaMessageCell.swift
//  EEChatUI
//
//  Created by Snow on 2021/5/20.
//

import UIKit

public class MediaMessageCell: MessageContentCell {
    
    open lazy var imageView: MessageImageView = {
        let imageView = MessageImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.contentMode = .scaleAspectFill
        messageContainerView.addSubview(imageView)
        return imageView
    }()
    
    public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
//        guard let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes else {
//            return
//        }
//        
//        var frame = messageContainerView.bounds
//        frame.origin.x += attributes.messageContainerPadding.left
//        frame.origin.y += attributes.messageContainerPadding.top
//        frame.size.width -= attributes.messageContainerPadding.left + attributes.messageContainerPadding.right
//        frame.size.height -= attributes.messageContainerPadding.top + attributes.messageContainerPadding.bottom
//        imageView.frame = frame
        
        imageView.frame = messageContainerView.bounds
    }
    
    public override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        switch message.content {
        case .image(let item), .video(let item):
            imageView.setImage(with: item.thumbnail)
        default:
            fatalError()
        }
    }
    
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: messageContainerView)

        guard imageView.frame.contains(touchLocation) else {
            super.handleTapGesture(gesture)
            return
        }
        delegate?.didTapImage(in: self)
    }
}
