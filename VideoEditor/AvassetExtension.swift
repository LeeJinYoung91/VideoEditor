//
//  AvassetExtension.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 7. 11..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation

extension AVAsset {
    func normalizingMediaDuration() -> AVAsset? {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        guard let video = tracks(withMediaType: AVMediaType.video).first else {
            return nil
        }
        
        guard let audio = tracks(withMediaType: AVMediaType.audio).first else {
            return nil
        }
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let duration = video.timeRange.duration.seconds > audio.timeRange.duration.seconds ? audio.timeRange.duration : video.timeRange.duration
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,duration), of: video, at: kCMTimeZero)
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: audio, at: kCMTimeZero)
        }catch{
            return nil
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,duration)
        
        return mixComposition
    }
}
