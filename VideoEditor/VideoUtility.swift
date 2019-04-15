//
//  MergeVideoUtility.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit

class VideoUtility : NSObject {
    static let shared:VideoUtility = VideoUtility()
    
    func mergedVideo(videos:[AVAsset], successListener:((URL)->Void)?, errorListener:(()->Void)?) {
        var insertTime = kCMTimeZero
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        let arrayVideos:[AVAsset] = videos
        
        let mixComposition = AVMutableComposition.init()
        
        for videoAsset in arrayVideos {
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = kCMTimeZero
                let duration = videoAsset.duration
                
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(startTime, duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                videoCompositionTrack?.preferredTransform = videoTrack.preferredTransform
                
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(startTime, duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!,
                                                                           asset: videoAsset,
                                                                           atTime: insertTime)
                
                let endTime = CMTimeAdd(insertTime, duration)
                layerInstruction.setOpacity(0, at: endTime)
                
                arrayLayerInstructions.append(layerInstruction)
                
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = UIScreen.main.bounds.size
        
        let path = NSTemporaryDirectory().appending("mergedVideo.mov")
        let exportURL = URL.init(fileURLWithPath: path)
        
        do {
            try FileManager.default.removeItem(at: exportURL)
        } catch {}

        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mov
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainComposition
        
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: successListener, failListener: errorListener)
            }
        })
    }
}

extension VideoUtility {
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    fileprivate func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: .video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var aspectFillRatio:CGFloat = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            aspectFillRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = UIScreen.main.bounds.width/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let posY = UIScreen.main.bounds.height/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: atTime)
            
        } else {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = UIScreen.main.bounds.width/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let posY = UIScreen.main.bounds.height/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)
            
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                concat = fixUpsideDown.concatenating(scaleFactor).concatenating(moveFactor)
            }
            
            instruction.setTransform(concat, at: atTime)
        }
        
        return instruction
    }
    
    fileprivate func exportDidFinish(exporter:AVAssetExportSession?, videoURL:URL, completion:((URL)->Void)?, failListener:(()->Void)?) {
        if exporter?.status == AVAssetExportSessionStatus.completed {
            if completion != nil {
                completion!(videoURL)
            }

        }
        else if exporter?.status == AVAssetExportSessionStatus.failed {
            if failListener != nil {
                failListener!()
            }
        }
    }
}
