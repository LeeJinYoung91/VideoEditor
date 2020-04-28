//
//  OverlayVideoViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 25/04/2019.
//  Copyright © 2019 JinYoung Lee. All rights reserved.
//

import Foundation

class OverlayVideoViewController: UIViewController {
    @IBOutlet weak var inputField: UITextField!
    private var selectedVideoURL: URL?
    private final let numberOfSubtitle: Int = 5

    @IBAction func selectAsset(_ sender: Any) {
        openVideoPicker(listener: nil)
    }
    
    @IBAction func startMerge(_ sender: Any) {
        addTextIntoMovie()
    }
    
    private func addTextIntoMovie() {
        guard let url = selectedVideoURL else {
            return
        }
        
        let fileURL = url
        let composition = AVMutableComposition()
        let vidAsset = AVURLAsset(url: fileURL)
        
        let vtrack =  vidAsset.tracks(withMediaType: .video)
        let videoTrack: AVAssetTrack = vtrack[0]
        
        guard let compositionvideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }
        do {
            try compositionvideoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: vidAsset.duration), of: videoTrack, at: CMTime.zero)
        } catch {
            print("error")
            return
        }
        
        let size = videoTrack.naturalSize
        
        let imglogo = UIImage(named: "like")
        let imglayer = CALayer()
        imglayer.contents = imglogo?.cgImage
        imglayer.frame = CGRect(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2, width: 100, height: 100)
        imglayer.masksToBounds = true
        
        let titleLayer = CATextLayer()
        titleLayer.foregroundColor = UIColor.white.cgColor
        titleLayer.string = inputField.text
        titleLayer.font = UIFont(name: "Helvetica", size: 28)
        titleLayer.alignmentMode = CATextLayerAlignmentMode.center
        titleLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        titleLayer.add(getSubtitlesAnimation(duration: 1, startTime: 2), forKey: nil)

        let titleLayer2 = CATextLayer()
        titleLayer2.foregroundColor = UIColor.red.cgColor
        titleLayer2.string = "two"
        titleLayer2.font = UIFont(name: "Helvetica", size: 28)
        titleLayer2.alignmentMode = CATextLayerAlignmentMode.center
        titleLayer2.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        titleLayer2.add(getSubtitlesAnimation(duration: 1, startTime: 4), forKey: nil)

        
        let titleLayer3 = CATextLayer()
        titleLayer3.foregroundColor = UIColor.blue.cgColor
        titleLayer3.string = "three"
        titleLayer3.font = UIFont(name: "Helvetica", size: 28)
        titleLayer3.alignmentMode = CATextLayerAlignmentMode.center
        titleLayer3.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        titleLayer3.add(getSubtitlesAnimation(duration: 1, startTime: 6), forKey: nil)

        let titleLayer4 = CATextLayer()
        titleLayer4.foregroundColor = UIColor.green.cgColor
        titleLayer4.string = "four"
        titleLayer4.font = UIFont(name: "Helvetica", size: 28)
        titleLayer4.alignmentMode = CATextLayerAlignmentMode.center
        titleLayer4.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        titleLayer4.add(getSubtitlesAnimation(duration: 1, startTime: 8), forKey: nil)

        let titleLayer5 = CATextLayer()
        titleLayer5.foregroundColor = UIColor.yellow.cgColor
        titleLayer5.string = "five"
        titleLayer5.font = UIFont(name: "Helvetica", size: 28)
        titleLayer5.alignmentMode = CATextLayerAlignmentMode.center
        titleLayer5.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        titleLayer5.add(getSubtitlesAnimation(duration: 1, startTime: 10), forKey: nil)

        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(titleLayer)
        parentlayer.addSublayer(titleLayer2)
        parentlayer.addSublayer(titleLayer3)
        parentlayer.addSublayer(titleLayer4)
        parentlayer.addSublayer(titleLayer5)
        
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionvideoTrack)
        layerinstruction.setTransform(compositionvideoTrack.preferredTransform, at: CMTime.zero)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: vidAsset.duration)
        
        mainInstruction.layerInstructions = [layerinstruction]
        
        let mainCompositionInst = AVMutableVideoComposition()
        mainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainCompositionInst.renderSize = size
        mainCompositionInst.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        mainCompositionInst.instructions = [mainInstruction]
        
        
        let movieDestinationUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "mergeVideo.mp4")
        if FileManager.default.fileExists(atPath: movieDestinationUrl.path) {
            do {
                try FileManager.default.removeItem(at: movieDestinationUrl)
                print("removed")
            } catch {
                
            }
        }

        let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = movieDestinationUrl
        assetExport.videoComposition = mainCompositionInst
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case .completed:
                UISaveVideoAtPathToSavedPhotosAlbum(movieDestinationUrl.path, nil, nil, nil)
                print("success import text")
                break
            case .failed:
                print("fail")
                break
            case .cancelled:
                print("cancel")
                break
            default:
                break
            }
        }
    }
    
    private func getSubtitlesAnimation(duration: CFTimeInterval,startTime:Double)->CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath:"opacity")
        animation.duration = duration
        animation.values = [0,0.5,1,0.5,0]
        animation.keyTimes = [0,0.25,0.5,0.75,1]
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.both
        animation.beginTime = startTime
        return animation
    }
}

extension OverlayVideoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL {
            selectedVideoURL = videoURL
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension OverlayVideoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
}
