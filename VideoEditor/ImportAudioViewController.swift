//
//  ImportAudioViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 15/04/2019.
//  Copyright © 2019 JinYoung Lee. All rights reserved.
//

import Foundation

class ImportAudioViewController: UIViewController {
    override func viewDidLoad() {
        
    }
    
    private func getAudioFileFromName(_ name: String) -> URL? {
        if let audioPath = Bundle.main.path(forResource: name, ofType: "mp3") {
            return URL(fileURLWithPath: audioPath)
        }
        
        return nil
    }
    
    private func isVideoPortrait(track: AVAssetTrack)-> Bool{
        let videoTransform = track.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            return true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            return true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            return false
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            return false
        }
        
        return true
    }
    
}

extension ImportAudioViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? URL, let audioURL = getAudioFileFromName("uplink") {
            VideoUtility.shared.mergeAudioWithURL(videoUrl: videoURL, audioPath: audioURL.path, savePath: nil) { (success, pathURL) in
                print("result path: \(pathURL), success: \(success)")
            }
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
