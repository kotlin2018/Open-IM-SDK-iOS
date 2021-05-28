//
//  MediaMessageSizeCalculator.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/20.
//

import UIKit

open class MediaMessageSizeCalculator: MessageSizeCalculator {

    open override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        switch message.content {
        case .image(let item), .video(let item):
            let min: CGFloat = 50
            let max: CGFloat = 150
            
            let imageWidth = CGFloat(item.width)
            let imageHeight = CGFloat(item.height)
            
            var width = imageWidth
            var height = imageHeight
            
            if width != 0 && height != 0 {
                if imageWidth > imageHeight {
                    width = imageWidth > max ? max : imageWidth < min ? min : imageWidth
                    height = width / imageWidth * imageHeight
                } else {
                    height = imageHeight > max ? max : imageHeight < min ? min : imageHeight
                    width = height / imageHeight * imageWidth
                }
            }
            
            if width == 0 {
                width = min
            }
            if height == 0 {
                height = min
            }
            
            return CGSize(width: width, height: height)
        default:
            fatalError()
        }
    }
    
}
