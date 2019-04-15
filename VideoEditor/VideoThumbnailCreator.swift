//
//  VideoThumbnailCreator.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 29..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit

class VideoThumbnailCreator : NSObject {
    private let numberOfThumbnailCount:CGFloat = 15
    var thumbnailViews = [UIImageView]()
    
    private func addImagesToView(images: [UIImage], view: UIView){
        
        self.thumbnailViews.removeAll()
        var xPos: CGFloat = 0.0
        var width: CGFloat = 0.0
        for image in images{
            DispatchQueue.main.async {
                if xPos + view.frame.size.height < view.frame.width{
                    width = view.frame.width / self.numberOfThumbnailCount
                }else{
                    width = view.frame.width - xPos
                }
                
                let imageView = UIImageView(image: image)
                imageView.alpha = 0
                imageView.contentMode = UIViewContentMode.scaleAspectFill
                imageView.clipsToBounds = true
                imageView.frame = CGRect(x: xPos,
                                         y: 0.0,
                                         width: width,
                                         height: view.frame.size.height)
                self.thumbnailViews.append(imageView)
                
                
                view.addSubview(imageView)
                UIView.animate(withDuration: 0.2, animations: {() -> Void in
                    imageView.alpha = 1.0
                })
                view.sendSubview(toBack: imageView)
                xPos = xPos + view.frame.width / self.numberOfThumbnailCount
            }
        }
    }

    func updateThumbnails(view: UIView, videoURL: URL, duration: Float64) {
        
        var thumbnails = [UIImage]()
        var offset: Float64 = 0
        
        
        for view in self.thumbnailViews{
            DispatchQueue.main.sync {
                view.removeFromSuperview()
            }
        }
        
        for i in 0..<Int(self.numberOfThumbnailCount){
            let thumbnail = EditorHelper.thumbnailFromVideo(videoUrl: videoURL,
                                                             time: CMTimeMake(Int64(offset), 1))
            offset = Float64(i) * (duration / Float64(self.numberOfThumbnailCount))
            thumbnails.append(thumbnail)
        }
        self.addImagesToView(images: thumbnails, view: view)
    }
}
