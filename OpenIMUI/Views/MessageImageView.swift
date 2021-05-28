//
//  MessageImageView.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/8.
//

import UIKit
import Kingfisher

open class MessageImageView: AnimatedImageView {
    
    open func setImage(with url: URL?, placeholder: UIImage? = nil) {
        kf.setImage(with: url, placeholder: placeholder)
    }
    
}
