//
//  TTSSTTViewController.swift
//  VideoEditor
//
//  Created by JinYoung Lee on 26/04/2019.
//  Copyright © 2019 JinYoung Lee. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import AudioToolbox

class TTSSTTViewController: UIViewController {
    @IBOutlet weak var inputTextView: UITextView!
    private let speechRecognizer = SFSpeechRecognizer(locale: NSLocale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var stopButton: UIButton?
    private var willStopRecord: Bool = false
    private var onRecord: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextView.text = nil
        inputTextView.delegate = self
    }
    
    @IBAction func talkToSpeech(_ sender: Any) {
        guard let inputText = inputTextView.text else {
            return
        }
        if let language = NSLocale.preferredLanguages.first {
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: inputText)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            synthesizer.speak(utterance)
        }
    }
    
    @IBAction func speechToText(_ sender: Any) {
        speechRecognizer?.delegate = self
        if audioEngine.isRunning {
            recognitionRequest?.endAudio()
            audioEngine.stop()
        }
        startRecording()
        stopButton = UIButton(frame: CGRect(x: (view.bounds.width - 140)/2, y: view.bounds.height - 120, width: 140, height: 40))
        stopButton?.backgroundColor = UIColor.yellow
        stopButton?.setTitleColor(UIColor.black, for: .normal)
        stopButton?.setTitle(" STOP ", for: .normal)
        stopButton?.addTarget(self, action: #selector(onClickStopRecordButton), for: .touchUpInside)
        if stopButton != nil {
            view.addSubview(stopButton!)
        }
    }
    
    @objc private func onClickStopRecordButton() {
        willStopRecord = true
        stopButton?.removeFromSuperview()
    }
    
    private func startRecording() {
        guard recognitionTask == nil else {
            recognitionTask?.cancel()
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let err {
            print(err.localizedDescription)
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            recognitionTask?.cancel()
            return
        }
        recognitionRequest?.shouldReportPartialResults = true
        var isFinal = false
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { (taskResult, error) in
            if let result = taskResult {
                print(result.bestTranscription.formattedString)
                self.inputTextView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal || self.willStopRecord {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
    }
    
    @IBAction func onClickRecordButton(_ sender: Any) {
        if !onRecord {
            ScreenRecorderModule.sharedInstance.startRecording()
        } else {
            ScreenRecorderModule.sharedInstance.stopRecording()
        }
        onRecord = !onRecord
    }
}

extension TTSSTTViewController: SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate {
    
}


extension TTSSTTViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.elementsEqual("\n") {
            textView.resignFirstResponder()
        }
        return true
    }
}

