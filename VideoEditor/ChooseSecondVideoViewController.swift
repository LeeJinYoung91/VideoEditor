//
//  ChooseSecondVideoViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit
import Photos

class ChooseSecondVideoViewController: BaseSelectVideoViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mergeButton: UIButton!
    var firstVideoURL:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoContainerView = containerView
        self.button = mergeButton
        mergeButton.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func bindFirstVideoURL(videoURL:URL) {
        firstVideoURL = videoURL
    }
    
    @IBAction func pickVideo(_ sender: Any) {
       self.openVideoPicker()
    }
    
    @IBAction func clickMergeVideoButton(_ sender: Any) {
        if let videoURL = (videoPlayer?.currentItem?.asset as? AVURLAsset)?.url {            
            guard firstVideoURL != nil else {
                return
            }
            
            VideoUtility.shared.mergedVideo(videos: [AVAsset(url: firstVideoURL!), AVAsset(url: videoURL)], saveFolder: "temp", videoTitle: "title",  successListener: { (videoURL) in
                if let mergedViewController:MergedVideoViewController = self.storyboard?.instantiateViewController(withIdentifier: "id_mergeVideo") as? MergedVideoViewController {
                    mergedViewController.bindMergedVideoURL(url: videoURL)
                    self.navigationController?.pushViewController(mergedViewController, animated: true)
                }
            }, errorListener: nil)
        }
    }
}
