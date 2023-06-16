//
//  Speaker.swift
//

import Foundation

import AVFoundation
import CallKit
import Foundation

/// This protocol is used to generate speech
protocol Speaker {
    /// Speak a raw text string through a speech synthesizer
    func speak(_ text: String) -> Error?
    func stopSpeaking()
}

class SpeakerConcrete: NSObject, Speaker {
    fileprivate var synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String) -> Error? {
        guard !isOnPhoneCall() else {
            return NSError(domain: "SpeakerConcreteUserOnPhoneCallErrorDomain",
                           code: 0,
                           userInfo: [NSLocalizedDescriptionKey: "Voice blocked by phone call."])
        }

        let error = enableSession()
        let utterance = AVSpeechUtterance(string: text)
        synth.speak(utterance)
        return error
    }

    func stopSpeaking() {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
    }

    // MARK: Phone Call Dodging

    private func isOnPhoneCall() -> Bool {
        for call in CXCallObserver().calls {
            if !call.hasEnded {
                return true
            }
        }
        return false
    }

    private func enableSession() -> Error? {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            return nil
        } catch {
            return error
        }
    }

    func disableSession() -> Error? {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            return nil
        } catch {
            return error
        }
    }
}

extension SpeakerConcrete: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard !synthesizer.isSpeaking else {
            return
        }
        _ = disableSession()
    }
}
