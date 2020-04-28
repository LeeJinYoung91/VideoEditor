
//  ScreenRecorderModule.swift
//  ScreenRecorder
//
//  Created by JinYoung Lee on 2017. 12. 14..
//  Copyright © 2017년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVFoundation
import ReplayKit
import Photos

@objc(ScreenRecorderModule)
@objcMembers public class ScreenRecorderModule: NSObject, RPScreenRecorderDelegate, AVAudioRecorderDelegate {
    enum CALL_BACK_TYPE: Int {
        case CALLBACK_START = 0
        case CALLBACK_START_FAIL
        case CALLBACK_STOP
        case CALLBACK_STOP_FAIL
        case CALLBACK_CANCEL
        case CALLBACK_CANCEL_FAIL
    }
    
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var avAssetWriter: AVAssetWriter?
    private var moviePath: String?
    private var outputPath: URL?
    private var fileName: String?
    private var firstCheckPermission: Bool = false
    private var pauseRecording: Bool = false
    private var isStopRecording: Bool = false
    private var willRecordWithMic: Bool = true
    static let sharedInstance: ScreenRecorderModule = ScreenRecorderModule()
    private var micRecorder: AVAudioRecorder?

    func pauseRecord() {
        pauseRecording = true
    }
    
    func resumeRecord() {
        pauseRecording = false
    }
    
    var willEnableMic: Bool {
        set {
            willRecordWithMic = newValue
        } get {
            return willRecordWithMic
        }
    }
    
    func readyToWriterAVAsset(){
        let recordScreenSize:CGSize = UIScreen.main.bounds.size
        let scale:CGFloat = UIScreen.main.scale
        let bitrate = (recordScreenSize.width * scale) * (recordScreenSize.height * scale) * 10
        
        let videoCompress:NSDictionary = [AVVideoAverageBitRateKey: bitrate,
                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                          AVVideoH264EntropyModeKey: AVVideoH264EntropyModeKey,
                                          AVVideoMaxKeyFrameIntervalKey: 60,
                                          AVVideoMaxKeyFrameIntervalDurationKey: 0]
        
        let videoSetting:[String:Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                         AVVideoWidthKey: NSNumber(value: ceilf(Float(recordScreenSize.width / 16)) * 16 * Float(scale)),
                                         AVVideoHeightKey: NSNumber(value: ceilf(Float(recordScreenSize.height / 16)) * 16 * Float(scale)),
                                         AVVideoCompressionPropertiesKey: videoCompress];
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSetting)
        
        audioInput = nil
        var channelLayout = AudioChannelLayout()
        if willRecordWithMic {
            let audioSetting:[String:Any] = [AVFormatIDKey: UInt(kAudioFormatMPEG4AAC),
                                             AVSampleRateKey: 12000,
                                             AVNumberOfChannelsKey: 1,
                                             AVEncoderAudioQualityForVBRKey: AVAudioQuality.high.rawValue]
            let audioURL = getMicRecordFileURL()
            if FileManager.default.fileExists(atPath: audioURL.path) {
                try? FileManager.default.removeItem(atPath: audioURL.path)

            }
            
            micRecorder = try? AVAudioRecorder(url: audioURL, settings: audioSetting)
            micRecorder?.delegate = self
        } else {
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            let audioSetting:[String:Any] = [AVFormatIDKey: UInt(kAudioFormatMPEG4AAC),
                                             AVSampleRateKey: 44100,
                                             AVNumberOfChannelsKey: 2,
                                             AVChannelLayoutKey: NSData(bytes:&channelLayout, length:MemoryLayout.size(ofValue: channelLayout))]
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSetting)
            micRecorder = nil
        }
        
        let filePath = getSavedFileURL()
        if (FileManager.default.fileExists(atPath: filePath)) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch let error as NSError {
                NSLog("delete error: %@", error.description)
            }
        }
        
        outputPath = URL(fileURLWithPath: filePath)
        
        do{
            try self.avAssetWriter = AVAssetWriter(outputURL: self.outputPath!, fileType: AVFileType.mov)
        } catch let error as NSError {
            NSLog("AssetWriter Error: %@", error.description)
        }
        videoInput?.expectsMediaDataInRealTime = true
        audioInput?.expectsMediaDataInRealTime = true
        videoInput?.mediaTimeScale = 60
        avAssetWriter?.movieTimeScale = 60
        
        if (avAssetWriter?.canAdd(videoInput!))! {
            avAssetWriter?.add(videoInput!)
        }
        
        if !willRecordWithMic {
            if (avAssetWriter?.canAdd(audioInput!))! {
                avAssetWriter?.add(audioInput!)
            }
        }
    }
    
    private func getSavedFileURL() -> String {
        moviePath = ((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray).object(at: 0) as! NSString).appendingPathComponent("Record")
        
        if !(FileManager.default.fileExists(atPath: self.moviePath!)) {
            do {
                try FileManager.default.createDirectory(atPath: self.moviePath!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog("Create Directory Error: %@", error.description)
            }
        }
        
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let timeString:String = dateFormatter.string(from: Date())
        let filename = String(format: "Record_%@.mov", timeString)
        fileName = filename
        let documentPath:String = String(format: "%@/%@", self.moviePath!, filename)
        return documentPath
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getMicRecordFileURL() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.m4a")
    }
    
    public func startRecording(){
        let screenRecorder:RPScreenRecorder = RPScreenRecorder.shared()
        screenRecorder.delegate = self
        var frameCount = 0;
        readyToWriterAVAsset()
        if #available(iOS 11.0, *) {
            if screenRecorder.isAvailable {
                screenRecorder.startCapture(handler: {(sampleBuffer, bufferType, error) in
                    guard error == nil else {
                        return
                    }

                    guard CMSampleBufferDataIsReady(sampleBuffer) && CMSampleBufferIsValid(sampleBuffer) else {
                        return
                    }

                    if let sample:CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer) as CMTime? {
                        if CMTIME_IS_VALID(sample) {
                            if self.avAssetWriter?.status == AVAssetWriter.Status.unknown {
                                if let started = self.avAssetWriter?.startWriting() {
                                    if !started {
                                        return
                                    }
                                    self.avAssetWriter?.startSession(atSourceTime: sample)
                                    if self.willRecordWithMic {
                                        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
                                        try? AVAudioSession.sharedInstance().setActive(true)
                                        if AVAudioSession.sharedInstance().recordPermission == .granted {
                                            self.micRecorder?.record()
                                        }
                                    }
                                } else {
                                    return
                                }
                            }
                            
                            if self.avAssetWriter?.status == AVAssetWriter.Status.failed {
                                self.forceStopRecordMic()
                                self.forceStopRecord()
                                return
                            }
                            
                            if self.avAssetWriter?.status == AVAssetWriter.Status.writing {
                                var assetInput:AVAssetWriterInput?
                                switch bufferType {
                                case .video:
                                    assetInput = self.videoInput
                                    break
                                case .audioApp:
                                    guard !self.willRecordWithMic else {
                                        break
                                    }
                                    assetInput = self.audioInput
                                    break
                                case .audioMic:
                                    break
                                @unknown default: break
                                    
                                }
                                
                                if let writer = assetInput {
                                    if writer.isReadyForMoreMediaData {
                                        writer.append(sampleBuffer)
                                    }
                                }
                                frameCount += 1
                            } else {
                                self.forceStopRecordMic()
                                self.forceStopRecord()
                            }
                        }
                    }
                }, completionHandler: { (error) in
                    print("## is error: \(error?.localizedDescription)")
                })
            }
        }
    }
    
    private func isVideoPortrait(track: AVAssetTrack)-> Bool{
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
    
    public func forceStopRecord() {
        self.isStopRecording = true
        if #available(iOS 11.0, *) {
            let screenRecorder:RPScreenRecorder = RPScreenRecorder.shared()
            screenRecorder.stopCapture(handler: { [weak self](error) in
                self?.avAssetWriter?.cancelWriting()
            })
        }
    }
    
    public func cancelRecord() {
        forceStopRecordMic()
        forceStopRecord()
    }
    
    private func forceStopRecordMic() {
        if willRecordWithMic {
            micRecorder?.stop()
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
        }
    }
    
    public func stopRecording(){
        self.isStopRecording = true
        if avAssetWriter?.status == AVAssetWriter.Status.unknown {
            forceStopRecordMic()
            forceStopRecord()
            return
        }
        
        let screenRecorder:RPScreenRecorder = RPScreenRecorder.shared()
        guard screenRecorder.isRecording else {
            if avAssetWriter?.status == AVAssetWriter.Status.writing {
                avAssetWriter?.cancelWriting()
            }
            return
        }
        
        guard screenRecorder.isAvailable else {
            avAssetWriter?.cancelWriting()
            return
        }
        
        if #available(iOS 11.0, *) {
            screenRecorder.stopCapture { (error) in
                if error != nil {
                    return
                }
                
                if self.willRecordWithMic {
                    self.micRecorder?.stop()
                }
                if self.avAssetWriter?.status == AVAssetWriter.Status.writing {
                    self.videoInput?.markAsFinished()
                    if !self.willRecordWithMic {
                        self.audioInput?.markAsFinished()
                    }
                    self.avAssetWriter?.finishWriting(completionHandler: {
                        print("stop record")
                        if self.willRecordWithMic && AVAudioSession.sharedInstance().recordPermission == .granted {
                            self.mergeFilesWithUrl()
                        }
                    })
                } else {
                    self.avAssetWriter?.cancelWriting()
                }
            }
        }
    }
    
    private func mergeFilesWithUrl()
    {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let videoAsset : AVAsset = AVAsset(url: getOutputPath())
        let audioAsset : AVAsset = AVAsset(url: getMicRecordFileURL())
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        guard let videoAssetTrack : AVAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            return
        }
        guard let audioAssetTrack : AVAssetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            return
        }
        
        try? mutableCompositionVideoTrack.first?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: CMTime.zero)
        try? mutableCompositionAudioTrack.first?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration), of: audioAssetTrack, at: CMTime.zero)
        
        totalVideoCompositionInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration)
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTime(seconds: 1, preferredTimescale: 60)
        if isVideoPortrait(track: videoAssetTrack) {
            mutableVideoComposition.renderSize = CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width)
        } else {
            mutableVideoComposition.renderSize = videoAssetTrack.naturalSize
        }
        let savePathUrl = URL(fileURLWithPath: getSavedFileURL())
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        if FileManager.default.fileExists(atPath: savePathUrl.path) {
            try? FileManager.default.removeItem(at: savePathUrl)
        }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.soloAmbient)
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case .completed:
                let outputURL = self.getOutputPath()
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    FileManager.default.fileExists(atPath: outputURL.path)
                }
                self.startDownloadVideo(path: savePathUrl, completeHandler: { (success, error) in
                    if success {
                        print("success")
                    }
                })
                break
            case .failed:
                break
            case .cancelled:
                break
            default:
                break
            }
        }
    }
    
    func getOutputPath() -> URL {
        return outputPath!
    }
    
    func getFileName() -> String {
        return fileName!
    }
    
    public func startDownloadVideo(path: URL, completeHandler:((Bool, Error?)->Void)?) {
        getAlbum { (assetCollection) in
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path)
                let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
            }, completionHandler: completeHandler)
        }
    }
    
    private func getAlbum(completeHandler:@escaping (PHAssetCollection) -> Void) {
        let fetchOption = PHFetchOptions()
        fetchOption.predicate = NSPredicate(format: "title = %@", "Test")
        let phCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: fetchOption)
        
        if let album = phCollection.firstObject {
            completeHandler(album)
        } else {
            createAlbum(completeHandler: completeHandler)
        }
    }
    
    private func createAlbum(completeHandler:@escaping (PHAssetCollection) -> Void) {
        var album:PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Test")
            album = changeRequest.placeholderForCreatedAssetCollection
        }) { (success, error) in
            if success {
                let collectionList = album.map { PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [$0.localIdentifier], options: nil)}
                if let assetCollction = collectionList?.firstObject {
                    completeHandler(assetCollction)
                }
            }
        }
    }
}
