//
//  MergeVideoUtility.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit

class VideoUtility: NSObject {
    static let shared: VideoUtility = VideoUtility()
    private let DefaultMoviePath = "EncodedMovie"

    private func getAudioFileFromName(_ name: String) -> URL? {
        if let audioPath = Bundle.main.path(forResource: name, ofType: "mp3") {
            return URL(fileURLWithPath: audioPath)
        }

        return nil
    }

    private func isVideoPortrait(track: AVAssetTrack) -> Bool {
        let videoTransform = track.preferredTransform

        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            return true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            return true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            return false
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            return false
        }

        return true
    }

    func mergeAudioWithURL(videoUrl: URL, audioPath: String, savePath: URL?, listener: ((Bool, URL) -> Void)?) {

        let audioUrl = URL(fileURLWithPath: audioPath)

        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()

        let videoAsset: AVAsset = AVAsset(url: videoUrl)
        let audioAsset: AVAsset = AVAsset(url: audioUrl)

        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)

        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else { return }
        try? mutableCompositionVideoTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: CMTime.zero)

        if let defaultAudioTrack = videoAsset.tracks(withMediaType: .audio).first {
            try? mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration), of: defaultAudioTrack, at: CMTime.zero)
        }
        if let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first {
            try? mutableCompositionAudioTrack[1].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration), of: audioAssetTrack, at: CMTime(seconds: 2, preferredTimescale: 1))
        }

        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration)

        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mutableVideoComposition.renderSize = videoAssetTrack.naturalSize

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePath
        assetExport.shouldOptimizeForNetworkUse = true

        var saveUrl = savePath
        if saveUrl == nil {
            let documentPath = ((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray).object(at: 0) as! NSString).appendingPathComponent(DefaultMoviePath)
            createDirectory(documentPath)
            
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
            let timeString: String = dateFormatter.string(from: Date())
            
            saveUrl = URL(fileURLWithPath: documentPath.appending(String(format: "audio_merge_video_%@.mp4", timeString)))
        }
        
        if FileManager.default.fileExists(atPath: saveUrl!.path) {
            do {
                try FileManager.default.removeItem(at: saveUrl!)
            } catch {

            }
        }

        assetExport.exportAsynchronously {
            listener?(assetExport.status == .completed, saveUrl!)
        }
    }

    struct InputText {
        var _text: String
        var _color = UIColor.black
        var _font = UIFont(name: "Helvetica", size: 28)

        init(_ text: String) {
            _text = text
        }
    }

    func addTextInputMovie(text: String, inputTime: CGFloat, fileURL: URL, listener: ((Bool, URL) -> Void)?) {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: fileURL)

        let tracks = videoAsset.tracks(withMediaType: .video)
        let videoTrack: AVAssetTrack = tracks[0]

        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        try? compositionVideoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAsset.duration), of: videoTrack, at: CMTime.zero)

        let size = videoTrack.naturalSize
        let textLayer = CATextLayer()
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.string = text
        textLayer.font = UIFont(name: "Helvetica", size: 28)
        textLayer.alignmentMode = CATextLayerAlignmentMode.natural
        textLayer.isWrapped = true
        textLayer.foregroundColor = UIColor.red.cgColor
        if let startTime = Double(exactly: inputTime) {
            textLayer.add(getSubtitlesAnimation(duration: 2, startTime: startTime), forKey: nil)
        }

        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(textLayer)

        let textSize = (textLayer.font as! UIFont).sizeOfString(string: text, constrainedToWidth: Double(parentlayer.frame.width))

        textLayer.frame = CGRect(x: size.width / 4, y: -size.height + textSize.height + textLayer.fontSize/2, width: size.width / 2, height: size.height)

        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerinstruction.setTransform(compositionVideoTrack.preferredTransform, at: CMTime.zero)

        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)

        mainInstruction.layerInstructions = [layerinstruction]

        let mainCompositionInst = AVMutableVideoComposition()
        mainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainCompositionInst.renderSize = size
        mainCompositionInst.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)

        mainCompositionInst.instructions = [mainInstruction]

        let movieDestinationUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "overLayVideo.mp4")
        if FileManager.default.fileExists(atPath: movieDestinationUrl.path) {
            do {
                try FileManager.default.removeItem(at: movieDestinationUrl)
            } catch {

            }
        }

        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = movieDestinationUrl
        assetExport.videoComposition = mainCompositionInst
        assetExport.exportAsynchronously {
            listener?(assetExport.status == .completed, movieDestinationUrl)
        }
    }

    func mergedVideo(videos: [AVAsset], saveFolder: String, videoTitle: String?, successListener: ((URL) -> Void)?, errorListener: ((Error?) -> Void)?) {
        var insertTime = CMTime.zero
        var arrayLayerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        let arrayVideos: [AVAsset] = videos

        let mixComposition = AVMutableComposition.init()

        for videoAsset in arrayVideos {
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }

            var audioTrack: AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }

            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

            do {
                let startTime = CMTime.zero
                let duration = videoAsset.duration

                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                videoCompositionTrack?.preferredTransform = videoTrack.preferredTransform

                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
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
            } catch {
                print("load track fail")
            }
        }

        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions

        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = UIScreen.main.bounds.size

        let documentPath = ((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray).object(at: 0) as! NSString).appendingPathComponent(DefaultMoviePath)
        var path = documentPath
        createDirectory(path)

        var filename = videoTitle
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let timeString: String = dateFormatter.string(from: Date())
        if filename == nil || filename!.isEmpty {
            filename = String(format: "merged_video_%@.mp4", timeString)
        }

        if !saveFolder.isEmpty {
            path.append("/\(saveFolder)/")
            createDirectory(path)
        }

        let exportURL = URL(fileURLWithPath: path.appending(filename!))

        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(at: exportURL)
            } catch {}
        }

        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainComposition

        exporter?.exportAsynchronously(completionHandler: {
            self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: successListener, failListener: errorListener)
        })
    }

    private func createDirectory(_ path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                print("\(err.localizedDescription) fail to create directory")
            }
        }
    }
}

extension VideoUtility {
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
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

        var aspectFillRatio: CGFloat = UIScreen.main.bounds.width / assetTrack.naturalSize.width
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

    fileprivate func exportDidFinish(exporter: AVAssetExportSession?, videoURL: URL, completion: ((URL) -> Void)?, failListener: ((Error?) -> Void)?) {
        if exporter?.status == AVAssetExportSession.Status.completed {
            if completion != nil {
                completion!(videoURL)
            }

        } else if exporter?.status == AVAssetExportSession.Status.failed {
            if failListener != nil {
                failListener!(exporter?.error)
            }
        }
    }

    fileprivate func getSubtitlesAnimation(duration: CFTimeInterval, startTime: Double) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.duration = duration
        //        animation.values = [0,0.2,0.5,1,0.5,0.2,0]
        //        animation.keyTimes = [0,0.1,0.2,0.4,0.6,0.8,1]
        animation.values = [0, 0.5, 1, 0.5, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.8, 1]
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.both
        animation.beginTime = startTime
        return animation
    }
}

extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: Double) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self], context: nil).size
    }
}
