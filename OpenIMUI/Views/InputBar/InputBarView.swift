//
//  InputBarView.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/12.
//

import UIKit

public protocol InputBarViewDelegate: InputBarRecordViewDelegate {
    func inputBarView(_ inputBarView: InputBarView, didSend text: String)
}

public class InputBarView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public weak var delegate: InputBarViewDelegate? {
        didSet {
            recordView.delegate = delegate
        }
    }
    
    private var textViewTopConstraint: NSLayoutConstraint!
    
    public lazy var textView: MessageTextView = {
        let textView = MessageTextView()
        textView.maxHeight = 67
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerRadius = 4
        textView.delegate = self
        textView.returnKeyType = .send
        textView.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
    }()
    
    private var recordViewTopConstraint: NSLayoutConstraint!
    
    public lazy var recordView = InputBarRecordView()
    
    public lazy var voiceButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(ImageCache.named("openim_icon_input_voice"), for: .normal)
        return button
    }()
    
    public lazy var moreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(ImageCache.named("openim_icon_input_more"), for: .normal)
        return button
    }()
    
    private func setupView() {
        bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 55)
        autoresizingMask = .flexibleHeight
        backgroundColor = UIColor(red: 0xE8 / 255.0, green: 0xF2 / 255.0, blue: 0xFF / 255.0, alpha: 1)
        
        addObserver()
        
        do {
            addSubview(voiceButton)
            
            NSLayoutConstraint.activate([
                voiceButton.heightAnchor.constraint(equalToConstant: 55),
                voiceButton.widthAnchor.constraint(equalToConstant: 42),
                voiceButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                voiceButton.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        
        do {
            addSubview(textView)
            let top = textView.topAnchor.constraint(equalTo: topAnchor, constant: 11)
            let leading = textView.leadingAnchor.constraint(equalTo: voiceButton.trailingAnchor)
            let bottom = textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11)
            NSLayoutConstraint.activate([top, leading, bottom])
            
            textViewTopConstraint = top
        }
        
        do {
            recordView.isHidden = true
            addSubview(recordView)
            let height = recordView.heightAnchor.constraint(equalToConstant: 33)
            let top = recordView.topAnchor.constraint(equalTo: topAnchor, constant: 11)
            let leading = recordView.leadingAnchor.constraint(equalTo: textView.leadingAnchor)
            let trailing = recordView.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
            let bottom = recordView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11)
            NSLayoutConstraint.activate([height, leading, trailing, bottom])
            
            recordViewTopConstraint = top
        }
        
        do {
            addSubview(moreButton)
            let height = moreButton.heightAnchor.constraint(equalToConstant: 55)
            let widht = moreButton.widthAnchor.constraint(equalToConstant: 42)
            let leading = moreButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor)
            let trailing = moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
            let bottom = moreButton.bottomAnchor.constraint(equalTo: bottomAnchor)
            
            NSLayoutConstraint.activate([height, widht, leading, trailing, bottom])
        }
    }
    
    deinit {
        removeObserver()
    }
    
    // MARK: - Private
    
    private func addObserver() {
        
    }
    
    private func removeObserver() {
        
    }
    
    // MARK: - Override
    
    open override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
    
    // MARK: - Action
    
    func showVoiceChangeAction() {
        recordView(isHidden: !recordView.isHidden)
        if recordView.isHidden {
            textView.becomeFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
    }
    
    private func recordView(isHidden: Bool) {
        if recordView.isHidden == isHidden {
            return
        }
        
        let image = ImageCache.named(isHidden ? "openim_icon_input_voice" : "openim_icon_input_keyboard")
        voiceButton.setImage(image, for: .normal)
        
        recordView.isHidden = isHidden
        textView.isHidden = !isHidden
        
        if isHidden {
            NSLayoutConstraint.activate([textViewTopConstraint])
            NSLayoutConstraint.deactivate([recordViewTopConstraint])
        } else {
            becomeFirstResponder()
            NSLayoutConstraint.activate([recordViewTopConstraint])
            NSLayoutConstraint.deactivate([textViewTopConstraint])
        }
    }
    
    internal func showMore(_ isShowMore: Bool) {
        if isShowMore {
            recordView(isHidden: true)
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    @objc
    fileprivate func sendAction() {
        if textView.text != "" {
            delegate?.inputBarView(self, didSend: textView.text)
            textView.text = ""
        }
    }
}

extension InputBarView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendAction()
            return false
        }
        return true
    }
}
