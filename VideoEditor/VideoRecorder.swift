//
//  VideoRecorder.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 2018. 7. 25..
//  Copyright © 2018년 JinYoung Lee. All rights reserved.
//

import Foundation
import AVKit
import Photos

class VideoRecorder : NSObject, AVCaptureFileOutputRecordingDelegate {
    private var isOnRecording:Bool = false
    private let captureSession:AVCaptureSession = AVCaptureSession()
    private var movieFileOutput:AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput:AVCaptureDeviceInput?
    private var audioDeviceInput:AVCaptureDeviceInput?
    private var targetPreviewView:UIView?
    private var previewLayer:AVCaptureVideoPreviewLayer?
    
    private static var instance:VideoRecorder = VideoRecorder()
    static var getInstance:VideoRecorder {
        get {
            return instance
        }
    }
    
    func bindPreviewView(_ previewView:UIView) {
        targetPreviewView = previewView
    }
    
    func recordMove() {
        isOnRecording ? onRecordStop() : onRecordStart()
        isOnRecording = !isOnRecording
    }
    
    private func onRecordStart() {
        prepareForRecordStart { (isDone) in
            if isDone {
                if let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let outputPath = documentPath.appendingPathComponent("output.mov")
                    try? FileManager.default.removeItem(at: outputPath)
                    
                    if let connection:AVCaptureConnection = self.movieFileOutput.connection(with: .video) {
                        guard connection.isActive else {
                            self.isOnRecording = false
                            return
                        }
                        
                        self.movieFileOutput.startRecording(to: outputPath, recordingDelegate: self)
                    } else {
                        self.isOnRecording = false
                    }
                } else {
                    self.isOnRecording = false
                }
            } else {
                self.isOnRecording = false
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("start record")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("stop record")
        print(outputFileURL.absoluteString)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }, completionHandler: nil)
    }
    
    private func prepareForRecordStart(doneListener:((Bool) -> Void)?) {
        let newDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInMicrophone, .builtInTelephotoCamera], mediaType: AVMediaType.video, position: .unspecified).devices
        
        for device in newDevices {
            guard device.hasMediaType(.video) else {
                continue
            }
            
            guard device.position == AVCaptureDevice.Position.back else {
                continue
            }
            
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .high
            captureSession.removeOutput(movieFileOutput)
            if videoDeviceInput != nil {
                captureSession.removeInput(videoDeviceInput!)
            }
            
            if audioDeviceInput != nil {
                captureSession.removeInput(audioDeviceInput!)
            }
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if let audioInput = AVCaptureDevice.default(for: .audio) {
                    audioDeviceInput = try AVCaptureDeviceInput(device: audioInput)
                }
                
                if videoDeviceInput != nil {
                    if captureSession.canAddInput(videoDeviceInput!) {
                        captureSession.addInput(videoDeviceInput!)
                    }
                }
                
                if audioDeviceInput != nil {
                    if captureSession.canAddInput(audioDeviceInput!) {
                        captureSession.addInput(audioDeviceInput!)
                    }
                }
            } catch {
                if doneListener != nil {
                    doneListener!(false)
                    return
                }
            }
            
            captureSession.addOutput(self.movieFileOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspect
            previewLayer?.frame = CGRect(x: (targetPreviewView?.frame.origin.x)!, y: (targetPreviewView?.frame.origin.y)!, width: (targetPreviewView?.frame.width)!, height: (targetPreviewView?.frame.height)! - 30)
            targetPreviewView?.layer.addSublayer(previewLayer!)
        
            captureSession.commitConfiguration()
            captureSession.startRunning()
                if doneListener != nil {
                    doneListener!(true)
                    return
            }
        }
     
    
        if doneListener != nil {
            doneListener!(false)
            return
        }
    }

    private func captureDevice(with position:AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let devices:[AVCaptureDevice] = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInMicrophone, .builtInTelephotoCamera], mediaType: AVMediaType.video, position: .unspecified).devices {
            
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        
        return nil
    }

    private func onRecordStop() {
        guard isOnRecording else {
            return
        }
        
        movieFileOutput.stopRecording()
    }

}
