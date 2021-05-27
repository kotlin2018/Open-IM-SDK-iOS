//
//  InputBarMoreView.swift
//  EEChatUI
//
//  Created by Snow on 2021/5/13.
//

import UIKit

public protocol InputBarMoreViewDelegate: AnyObject {
    func inputBarMoreView(_ inputBarMoreView: InputBarMoreView, didSelect index: Int)
}

public class InputBarMoreView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public weak var delegate: InputBarMoreViewDelegate?
    
    public var bottomConstraint: NSLayoutConstraint?
    
    private func setupView() {
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        let height = heightAnchor.constraint(equalToConstant: 100)
        NSLayoutConstraint.activate([height])
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        addSubview(stackView)
        do {
            stackView.translatesAutoresizingMaskIntoConstraints = false
            let top = stackView.topAnchor.constraint(equalTo: topAnchor)
            let bottom = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            let leading = stackView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let trailing = stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
            NSLayoutConstraint.activate([top, bottom, leading, trailing])
        }
        
        let views = [
            item(0, title: LocalizedString("Camera"), image: ImageCache.named("openim_icon_more_photo_shoot")),
            item(1, title: LocalizedString("Album"), image: ImageCache.named("openim_icon_more_photo")),
        ]
        for view in views {
            stackView.addArrangedSubview(view)
            
            let width = view.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1.0 / CGFloat(views.count))
            let height = view.heightAnchor.constraint(equalTo: stackView.heightAnchor)
            NSLayoutConstraint.activate([width, height])
        }
    }
    
    private func item(_ tag: Int, title: String, image: UIImage?) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .custom)
        button.tag = tag
        button.addTarget(self, action: #selector(itemAction(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: button.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor),
        ])
        
        let label = UILabel()
        label.textColor = UIColor(red: 0.11, green: 0.45, blue: 0.93, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.text = title
        button.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 7),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor),
        ])
        
        return view
    }
    
    var isShow = false {
        didSet {
            bottomConstraint?.constant = isShow ? -bounds.height : 0
            isHidden = !isShow
        }
    }
    
    // MARK: - Action
    
    @objc
    func itemAction(_ button: UIButton) {
        delegate?.inputBarMoreView(self, didSelect: button.tag)
    }
        
}
