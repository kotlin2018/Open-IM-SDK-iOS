//
//  ChatHistoryCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/25.
//

import UIKit
import OpenIM
import OpenIMUI

class ChatHistoryCell: UITableViewCell {
    
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func config(model: Message, info: UserInfo?, key: String) {
        if let info = info {
            nameLabel.text = info.getName()
            avatarView.setImage(with: info.icon,
                                placeholder: UIImage(named: "icon_default_avatar"))
        }
        
        timeLabel.text = OpenIMDateFormatter.shared.format(model.sendTime)
        switch model.content {
        case .text(let text), .unknown(_, let text):
            var text = text as NSString
            let regular = try! NSRegularExpression(pattern: key, options: [])
            var array = regular.matches(in: text as String, options: [], range: NSRange(location: 0, length: text.length))
            
            let count = 30 / key.count
            if array.count > count {
                array = Array(array[0..<count])
            }
            
            var offset = 0
            let location = array.first?.range.location ?? 0
            if location > 10 {
                offset = location - 5
                text = "..." + text.substring(from: offset) as NSString
                offset -= 3
            }
            
            let attributedText = NSMutableAttributedString(string: text as String)
            array.forEach { (result) in
                var range = result.range
                range.location -= offset
                attributedText.addAttributes([.foregroundColor : UIColor.eec.rgb(0x1B72EC)],
                                             range: range)
            }
            
            contentLabel.attributedText = attributedText
        default:
            fatalError()
        }
        

    }
    
}
