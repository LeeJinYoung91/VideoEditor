//
//  VideoEditorViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 29..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class VideoEditorViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SAVideoRangeSliderDelegate {
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var thumbnailContainer: UIView!
    private var videoPlayer:AVPlayer?
    private var videoLayer:AVPlayerLayer?
    
    private var trimStartPosition:Float64?
    private var trimEndPosition:Float64?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.openVideoPicker(listener: nil)
        slider.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Trim", style: .plain, target: self, action: #selector(trimVideo))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        makeLayerBounds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? URL {
            self.videoPlayer = AVPlayer(url: videoURL)
            self.videoLayer = AVPlayerLayer(player: self.videoPlayer)
            self.videoLayer?.videoGravity = .resizeAspect
            self.videoLayer?.masksToBounds = true
            self.videoContainer?.layer.sublayers = []
            self.videoContainer?.layer.addSublayer(self.videoLayer!)
            self.videoPlayer?.play()
            self.makeLayerBounds()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)
            
            let videoRangeSlider:SAVideoRangeSlider = SAVideoRangeSlider(frame: CGRect(x: 0, y: -3, width: self.thumbnailContainer.bounds.width, height: self.thumbnailContainer.bounds.height + 10), videoUrl: videoURL)
            videoRangeSlider.delegate = self
            videoRangeSlider.bubleText.font = UIFont.systemFont(ofSize: 10, weight: .regular)
            videoRangeSlider.setPopoverBubbleSize(120, height: 60)
            videoRangeSlider.topBorder.backgroundColor = UIColor(displayP3Red: 0.996, green: 0.951, blue: 0.502, alpha: 1)
            videoRangeSlider.bottomBorder.backgroundColor = UIColor(displayP3Red: 0.992, green: 0.902, blue: 0.004, alpha: 1)
            self.thumbnailContainer.addSubview(videoRangeSlider)
            
            if let duration = videoPlayer?.currentItem?.asset.duration {
                let endDuration = CMTimeGetSeconds(duration)
                let min = String(format: "%.0f", endDuration)
                let sec = String(format:"%.0f", Float((Int(endDuration * 100) % 100)) * 0.6)
                self.endTime.text = String(format:"%@:%@", min, sec)
//                VideoThumbnailCreator.init().update  7Thumbnails(view: thumbnailContainer, videoURL: videoURL, duration:CMTimeGetSeconds(duration))
                
                self.videoPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main, using: { (time) in
                    self.slider.value = Float(CMTimeGetSeconds(time))
                    self.setCurrentDisplayedTimeValue()
                })
                
                slider.maximumValue = Float(CMTimeGetSeconds(duration))
                slider.minimumValue = 0
            }
        }        
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func videoRange(_ videoRange: SAVideoRangeSlider!, didChangeLeftPosition leftPosition: CGFloat, rightPosition: CGFloat) {
        self.trimStartPosition = Float64(leftPosition)
        self.trimEndPosition = Float64(rightPosition)
    }
    
    @objc func trimVideo() {
        if let asset = (self.videoPlayer?.currentItem?.asset as? AVURLAsset) {
            let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
            if compatiblePresets.contains(AVAssetExportPresetHighestQuality) {
                let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                let tempPath = NSTemporaryDirectory()
                
                if FileManager.default.fileExists(atPath: tempPath.appending("tempMovie.mov")) {
                    try? FileManager.default.removeItem(at: URL(fileURLWithPath: tempPath.appending("tempMovie.mov")))
                }
                
                exportSession?.outputURL = URL(fileURLWithPath: tempPath.appending("tempMovie.mov"))
                exportSession?.outputFileType = AVFileType.mov
                
                guard self.trimStartPosition != nil && self.trimEndPosition != nil else {
                    return
                }
                
                let start = CMTimeMakeWithSeconds(self.trimStartPosition!, preferredTimescale: asset.duration.timescale)
                let duration = CMTimeMakeWithSeconds(self.trimEndPosition! - self.trimStartPosition!, preferredTimescale: asset.duration.timescale)
                exportSession?.timeRange = CMTimeRangeMake(start: start, duration: duration)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                    exportSession?.exportAsynchronously(completionHandler: {
                        if let errStr = exportSession?.error.debugDescription {
                            print(errStr)
                        }
                        
                        switch (exportSession?.status)! {
                        case .completed:
                            print("success to export")
                            if let tmpURL = exportSession?.outputURL {
                                self.savedVideo(tempVideoURL: tmpURL)
                            }
                            break
                        case .failed:
                            print("fail to export")
                            break
                        default:
                            print("?? ? ?   ?  ? ? ?? :)")
                            break
                            
                        }
                    })
                }
            }
        }
    }
    
    private func savedVideo(tempVideoURL:URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempVideoURL)
        }) { (success, error) in
            if success {
                print("save done")
            }
        }
    }
    
    private func makeLayerBounds() {
        if videoContainer != nil {
            videoLayer?.frame = (videoContainer?.bounds)!
        }
    }
    
    @IBAction func sliderValueChange(_ sender: Any) {
        if let slider = sender as? UISlider {
            if let duration = self.videoPlayer?.currentItem?.duration {
                guard CMTIME_IS_VALID(duration) else {
                    return
                }
                self.setCurrentDisplayedTimeValue()
                self.videoPlayer?.seek(to: CMTimeMake(value: Int64(slider.value), timescale: 1))
            }
        }
        self.videoPlayer?.pause()
    }
    
    @objc func sliderTouchUp() {
        self.videoPlayer?.play()
    }
    
    
    @objc private func playerItemDidReachEnd(notification:Notification) {
        if let item:AVPlayerItem = notification.object as? AVPlayerItem {
            if item == self.videoPlayer?.currentItem {
                self.videoPlayer?.seek(to: CMTime.zero)
                self.videoPlayer?.play()
                self.currentTime.text = "00:00"
            }
        }
    }
    
    private func setCurrentDisplayedTimeValue() {
        if let currentDisplayedTime = self.videoPlayer?.currentItem?.currentTime() {
            let currentTime = CMTimeGetSeconds(currentDisplayedTime)
            let min = String(format: "%.0f", currentTime)
            let sec = String(format:"%.0f", Float((Int(currentTime * 100) % 100)) * 0.6)
            self.currentTime.text = String(format:"%@:%@", min, sec)
        }
    }
}
