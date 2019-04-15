//
//  RecordViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 7. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation

class RecordViewController : UIViewController {
    
    @IBOutlet weak var videoView:UIView!
    
    @IBAction func onClickStop() {
        VideoRecorder.getInstance.bindPreviewView(videoView)
        VideoRecorder.getInstance.recordMove()
    }
}
