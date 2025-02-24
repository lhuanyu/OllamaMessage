//
//  SpeechRecognizer.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/22.
//

#if os(iOS)

import Accelerate
import AVFoundation
import Foundation
import Speech

final class SpeechRecognizer: NSObject, ObservableObject, @unchecked Sendable {
    
    static let shared = SpeechRecognizer()

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var fftSetup: FFTSetup?
    
    @Published @MainActor var transcribedText: String = ""
    @Published @MainActor var inputVolume: Float = 0.0
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("User has authorized speech recognition")
                case .denied:
                    print("User has denied speech recognition")
                case .restricted:
                    print("User's device does not support speech recognition")
                case .notDetermined:
                    print("User has not yet authorized speech recognition")
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
        } catch {
            print("Unable to activate audio session: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.addsPunctuation = true
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let error {
                print("Recognition failed: \(error.localizedDescription)")
            } else if let result = result {
                let transcription = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcribedText = transcription
                    print("Transcription: \(transcription)")
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.updateVolume(buffer: buffer)
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Unable to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func updateVolume(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        let frameLength = Int(buffer.frameLength)
        
        var rms: Float = 0.0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameLength))
        rms = sqrt(rms)
        
        let db = 20 * log10(rms)
        
        DispatchQueue.main.async {
            self.inputVolume = max(0, db + 80) / 80
        }
    }
}

#endif
