//
//  BaseSelectVideoViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit
import Photos

class BaseSelectVideoViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var videoPlayer:AVPlayer?
    var videoLayer:AVPlayerLayer?
    var videoContainerView:UIView?
    var button:UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.makeLayerBounds()
        videoPlayer?.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoPlayer?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayer?.pause()
    }
    
    func openVideoPicker() {
        self.openVideoPicker {
            self.button?.isEnabled = false
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? URL {
            self.videoPlayer = AVPlayer(url: videoURL)
            self.videoLayer = AVPlayerLayer(player: self.videoPlayer)
            self.videoLayer?.videoGravity = .resizeAspect
            self.videoLayer?.masksToBounds = true
            self.videoContainerView?.layer.sublayers = []
            self.videoContainerView?.layer.addSublayer(self.videoLayer!)
            self.makeLayerBounds()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)

            button?.isEnabled = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc private func playerItemDidReachEnd(notification:Notification) {
        if let item:AVPlayerItem = notification.object as? AVPlayerItem {
            if item == self.videoPlayer?.currentItem {
                self.videoPlayer?.seek(to: CMTime.zero)
                    self.videoPlayer?.play()
            }
        }
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func makeLayerBounds() {
        if videoContainerView != nil {
            videoLayer?.frame = (videoContainerView?.bounds)!
        }
    }
}
