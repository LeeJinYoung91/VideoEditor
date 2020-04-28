//
//  MergedVideoViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit
import Photos

class MergedVideoViewController : UIViewController {
    @IBOutlet weak var containerView: UIView!
    private var videoPlayer:AVPlayer?
    private var videoLayer:AVPlayerLayer?
    private var videoURL:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.assignMergedVideo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.videoLayer?.frame = self.containerView.bounds
        videoPlayer?.play()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func bindMergedVideoURL(url:URL) {
        videoURL = url
    }
    
    func assignMergedVideo() {
        guard videoURL != nil else {
            self.navigationController?.popToRootViewController(animated: true)
            return
        }
        self.videoPlayer = AVPlayer(url: videoURL!)
        self.videoLayer = AVPlayerLayer(player: self.videoPlayer)
        self.videoLayer?.videoGravity = .resizeAspect
        self.videoLayer?.masksToBounds = true
        self.containerView?.layer.sublayers = []
        self.containerView?.layer.addSublayer(self.videoLayer!)
        self.videoLayer?.frame = self.containerView.bounds
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)
    }
    
    @objc private func playerItemDidReachEnd(notification:Notification) {
        if let item:AVPlayerItem = notification.object as? AVPlayerItem {
            if item == self.videoPlayer?.currentItem {
                self.videoPlayer?.seek(to: CMTime.zero)
                self.videoPlayer?.play()
            }
        }
    }
    
    @IBAction func moveToTopViewController(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func savedCurrentVideo(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            if self.videoURL != nil {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL!)
            }
        }) { (success, error) in
            if success {
                self.presentAlertOnSavedVideo()
            }
        }
    }
    
    func presentAlertOnSavedVideo() {
        let alertVC:UIAlertController = UIAlertController(title: "Saved Photo", message: "Succeess", preferredStyle: .alert)
        self.present(alertVC, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                alertVC.dismiss(animated: true, completion: nil)
            })
        }
    }
}
