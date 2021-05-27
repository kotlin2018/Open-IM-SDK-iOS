//
//  InputBarAccessoryView.swift
//  EEChatUI
//
//  Created by Snow on 2021/5/21.
//

import UIKit

public class InputBarAccessoryView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    lazy var inputBarView: InputBarView = {
        let inputBarView = InputBarView()
        inputBarView.moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        inputBarView.voiceButton.addTarget(self, action: #selector(voiceChangeAction), for: .touchUpInside)
        inputBarView.translatesAutoresizingMaskIntoConstraints = false
        return inputBarView
    }()
    
    lazy var inputBarMoreView: InputBarMoreView = {
        let inputBarMoreView = InputBarMoreView()
        inputBarMoreView.translatesAutoresizingMaskIntoConstraints = false
        return inputBarMoreView
    }()

    private func setupView() {
        autoresizingMask = .flexibleHeight
        bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: inputBarView.bounds.height)
        
        let bottomConstraint = inputBarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        
        addSubview(inputBarView)
        NSLayoutConstraint.activate([
            inputBarView.topAnchor.constraint(equalTo: topAnchor),
            bottomConstraint,
            inputBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        addSubview(inputBarMoreView)
        NSLayoutConstraint.activate([
            inputBarMoreView.topAnchor.constraint(equalTo: inputBarView.bottomAnchor),
            inputBarMoreView.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputBarMoreView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        inputBarMoreView.isShow = false
        inputBarMoreView.bottomConstraint = bottomConstraint
        
        NotificationCenter.default.addObserver(self, selector: #selector(textDidBeginEditingNotification), name: UITextView.textDidBeginEditingNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func resignInputBar() {
        inputBarView.textView.resignFirstResponder()
        inputBarMoreView.isShow = false
        animate()
    }
    
    private func animate() {
        self.setNeedsLayout()
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Action
    
    @objc
    private func textDidBeginEditingNotification() {
        inputBarMoreView.isShow = false
        animate()
    }
    
    @objc
    private func voiceChangeAction() {
        inputBarView.showVoiceChangeAction()
        inputBarMoreView.isShow = false
        
        animate()
    }
    
    @objc
    private func moreAction() {
        inputBarMoreView.isShow = !inputBarMoreView.isShow
        inputBarView.showMore(inputBarMoreView.isShow)
        
        animate()
    }
    
    // MARK: - Override
    
    open override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
    
}
