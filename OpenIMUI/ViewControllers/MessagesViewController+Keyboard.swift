//
//  MessagesViewController+Keyboard.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/21.
//

import UIKit

internal extension MessagesViewController {
    // MARK: - Register / Unregister Observers

    func addKeyboardObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboard(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardObservers() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Notification Handlers
    
    @objc
    func keyboard(_ notification: Notification) {
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            keyboardIsShow = true
        case UIResponder.keyboardWillHideNotification:
            keyboardIsShow = false
        default:
            break
        }
        
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! CGFloat
        let endRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        guard self.presentedViewController == nil else {
            return
        }
        
        let newBottomInset = keyboardIsShow ? endRect.height : requiredScrollViewBottomInset()
        let differenceOfBottomInset = newBottomInset - messageCollectionViewBottomInset
        
        guard differenceOfBottomInset != 0 else {
            return
        }
        
        let contentOffsetY = messagesCollectionView.contentOffset.y + differenceOfBottomInset

        UIView.animate(withDuration: TimeInterval(duration)) {
            if contentOffsetY <= self.messagesCollectionView.contentSize.height {
                let contentOffset = CGPoint(x: self.messagesCollectionView.contentOffset.x, y: contentOffsetY)
                self.messagesCollectionView.setContentOffset(contentOffset, animated: false)
            }
            self.messageCollectionViewBottomInset = newBottomInset
        }
    }
    
    func requiredScrollViewBottomInset() -> CGFloat {
        let inputAccessoryViewHeight = inputAccessoryView?.frame.height ?? 0
        return max(0, inputAccessoryViewHeight)
    }
}
