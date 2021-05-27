//
//  ChatMediaHistoryCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/26.
//

import UIKit
import OpenIM

class ChatMediaHistoryCell: UICollectionViewCell {

    @IBOutlet var imageView: ImageView!
    
    var model: Message! {
        didSet {
            switch model.content {
            case .image(let item), .video(let item):
                imageView.setImage(with: item.thumbnail)
            default:
                fatalError()
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            
        }
    }
    
    @IBOutlet var selectBtn: UIButton!
    var selectCallback: (() -> Bool)?
    @IBAction func selectAction() {
        if let isSelected = selectCallback?() {
            selectBtn.isSelected = isSelected
        }
    }
}
