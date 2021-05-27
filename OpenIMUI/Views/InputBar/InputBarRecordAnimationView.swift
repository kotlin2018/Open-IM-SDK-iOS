//
//  InputBarRecordAnimationView.swift
//  EEChatUI
//
//  Created by Snow on 2021/5/12.
//

import UIKit

public class InputBarRecordAnimationView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    lazy var waverView: InputBarAudioWaverView = {
        let view = InputBarAudioWaverView()
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let top = view.topAnchor.constraint(equalTo: topAnchor, constant: 30)
        let centerX = view.centerXAnchor.constraint(equalTo: centerXAnchor)
        let width = view.widthAnchor.constraint(equalToConstant: 120)
        let height = view.heightAnchor.constraint(equalToConstant: 80)
        NSLayoutConstraint.activate([top, centerX, width, height])
        return view
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0xC3 / 255.0, green: 0xC3 / 255.0, blue: 0xC3 / 255.0, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 15)
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let top = label.topAnchor.constraint(equalTo: waverView.bottomAnchor, constant: 10)
        let centerX = label.centerXAnchor.constraint(equalTo: centerXAnchor)
        let bottom = label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30)
        NSLayoutConstraint.activate([top, centerX, bottom])
        return label
    }()

    private func setupView() {
        self.layer.cornerRadius = 8
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let width = widthAnchor.constraint(equalToConstant: 190)
        NSLayoutConstraint.activate([width])
    }

}
