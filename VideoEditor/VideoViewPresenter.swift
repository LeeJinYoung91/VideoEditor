//
//  VideoViewPresenter.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 6. 29..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AVKit

extension UIViewController {
    func openVideoPicker(listener:(()->Void)?) {
        let imagePicker:UIImagePickerController = UIImagePickerController()
        if let delegateViewController = self as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
            imagePicker.delegate = delegateViewController
        }
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        
        PHPhotoLibrary.requestAuthorization({status in
            if status == .authorized{
                DispatchQueue.main.async {
                    if listener != nil {
                        listener!()
                    }
                    self.navigationController?.present(imagePicker, animated: true, completion: nil)
                }
            }
        })
    }
}
