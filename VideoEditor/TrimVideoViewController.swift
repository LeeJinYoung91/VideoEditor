//
//  TrimVideoViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class TrimVideoViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
    @IBOutlet weak var containerView: UIView!
    var videoPlayer:AVPlayer?
    var videoLayer:AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.openVideoPicker(listener: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.makeLayerBounds()
        videoPlayer?.play()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? URL {
            let videoEditor:UIVideoEditorController = UIVideoEditorController()
            videoEditor.videoPath = videoURL.path
            videoEditor.videoQuality = .typeHigh
            videoEditor.delegate = self
            picker.dismiss(animated: true) {
                self.navigationController?.present(videoEditor, animated: true, completion:nil)
            }
        } else {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        displayCroppedVideo(videoPath: editedVideoPath)
        editor.dismiss(animated: true, completion: nil)
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismiss(animated: true, completion: nil)
    }
    
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        editor.dismiss(animated: true, completion: nil)
    }
    
    private func displayCroppedVideo(videoPath: String) {
        self.videoPlayer = AVPlayer(url: URL(fileURLWithPath: videoPath))
        self.videoLayer = AVPlayerLayer(player: self.videoPlayer)
        self.videoLayer?.videoGravity = .resizeAspect
        self.videoLayer?.masksToBounds = true
        self.containerView.layer.sublayers = []
        self.containerView.layer.addSublayer(self.videoLayer!)
        self.makeLayerBounds()
        self.videoPlayer?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)
    }
    
    private func makeLayerBounds() {
        videoLayer?.frame = containerView.bounds
    }
    
    @objc private func playerItemDidReachEnd(notification:Notification) {
        if let item:AVPlayerItem = notification.object as? AVPlayerItem {
            if item == self.videoPlayer?.currentItem {
                self.videoPlayer?.seek(to: CMTime.zero)
                self.videoPlayer?.play()
            }
        }
    }
    @IBAction func savedCurrentVideo(_ sender: Any) {
        if self.videoPlayer != nil {
            if let videoURL = (self.videoPlayer?.currentItem?.asset as? AVURLAsset)?.url {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }, completionHandler: { (saved, error) in
                    if saved {
                        self.presentAlertOnSavedVideo()
                    }
                })
            }
        }
    }
    
    @objc func presentAlertOnSavedVideo() {
        let alertVC:UIAlertController = UIAlertController(title: "Saved Photo", message: "Succeess", preferredStyle: .alert)
        self.present(alertVC, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                alertVC.dismiss(animated: true, completion: nil)
            })
        }
    }
}
