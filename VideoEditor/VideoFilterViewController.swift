//
//  VideoFilterViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 27..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit

class VideoFilterViewController : BaseSelectVideoViewController {
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    
    override func viewDidLoad() {
        self.videoContainerView = containerView
        super.viewDidLoad()
        buttonContainer.isHidden = true
        selectButton.isHidden = false
    }
    
    @IBAction func onClickSelect(_ sender: Any) {
        super.openVideoPicker()
    }
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        super.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        buttonContainer.isHidden = false
        selectButton.isHidden = true
    }
    
    @IBAction func clickFirst(_ sender: Any) {
        self.startFilterMovie(type: .NONE)
    }
    
    @IBAction func clickSecond(_ sender: Any) {
        self.startFilterMovie(type: .BLOOM)
    }
    
    @IBAction func clickThird(_ sender: Any) {
        self.startFilterMovie(type: .HIGHLIGHTED_SHADOW)
    }
    
    @IBAction func clickFourth(_ sender: Any) {
        self.startFilterMovie(type: .GLOOM)
    }
    
    @IBAction func clickFive(_ sender: Any) {
        self.startFilterMovie(type: .COMIC)
    }
    
    @IBAction func clickSix(_ sender: Any) {
        self.startFilterMovie(type: .INVERT_COLOR)
    }
    
    @IBAction func clickSeven(_ sender: Any) {
        self.startFilterMovie(type: .VIGNETTE)
    }
    
    @IBAction func clickNine(_ sender: Any) {
        self.startFilterMovie(type: .PHOTO_INSTANT)
    }
    
    private func startFilterMovie(type:VideoFilterUtility.FILTER_TYPE) {
        if let videoAsset = self.videoPlayer?.currentItem?.asset {
            self.videoPlayer?.currentItem?.videoComposition = videoAsset.setFilter(filterType: type)
        }
    }
}
