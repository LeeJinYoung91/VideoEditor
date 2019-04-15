//
//  ViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 22..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import UIKit
import AVKit
import Photos

class ChooseFirstVideoViewController: BaseSelectVideoViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoContainerView = containerView
        self.button = nextButton
        nextButton.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func pickVideo(_ sender: Any) {
        self.openVideoPicker()
    }
    
    @IBAction func clickNextButton(_ sender: Any) {
        if let videoURL = (videoPlayer?.currentItem?.asset as? AVURLAsset)?.url {
            if let secondViewController = storyboard?.instantiateViewController(withIdentifier: "id_secondVideoSelector") as? ChooseSecondVideoViewController {
                secondViewController.bindFirstVideoURL(videoURL: videoURL)
                self.navigationController?.pushViewController(secondViewController, animated: true)
            }
        }
    }
}

