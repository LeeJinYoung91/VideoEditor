//
//  EditorHelper.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 29..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit

class EditorHelper : NSObject {
    static func thumbnailFromVideo(videoUrl: URL, time: CMTime) -> UIImage{
        let asset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        do{
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        }catch{
            
        }
        return UIImage()
    }
    
    static func videoDuration(videoURL: URL) -> Float64{
        let source = AVURLAsset(url: videoURL)
        return CMTimeGetSeconds(source.duration)
    }
}
