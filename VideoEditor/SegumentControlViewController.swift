//
//  SegumentControlViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit

class SegumentControlViewController:UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private var onRecording:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func moveToMergeVideo(_ sender: Any) {
        self.moveToPage(identifier: "id_firstVideoSelector")
    }
    
    @IBAction func moveToCropVideo(_ sender: Any) {
        self.moveToPage(identifier: "id_cropVideo")
    }
    
    @IBAction func moveToVideoSelector(_ sender: Any) {
        self.moveToPage(identifier: "id_photoSelect")
    }
    
    @IBAction func filterVideo(_ sender: Any) {
        self.moveToPage(identifier: "id_filterVideo")
    }
    
    @IBAction func moveToVideoEditor(_ sender: Any) {
        self.moveToPage(identifier: "id_videoEditor")
    }
    
    @IBAction func onClickRecordButton(_ sender: Any) {
        self.moveToPage(identifier: "id_record")
    }
    
    private func moveToPage(identifier:String) {
        if let mergeStartVideo = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
            self.navigationController?.pushViewController(mergeStartVideo, animated: true)
        }
    }
}
