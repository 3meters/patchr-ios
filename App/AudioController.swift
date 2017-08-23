//
//  AudioController.swift
//  Teeny
//
//  Created by Jay Massena on 5/25/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import AVFoundation

class AudioController: NSObject {

    static let instance = AudioController()

    var player: AVAudioPlayer! = nil
    
    func playSystemSound(soundId: Int) {
        let systemSoundId: SystemSoundID = UInt32(soundId)
        AudioServicesPlaySystemSound(systemSoundId)
    }

    func play(sound: String) {
        
        do {
            /* Make app ready to takeover the device audio */
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: self.uriForFile(fileName: sound) as URL, fileTypeHint: nil)
            if sound == Sound.notification.rawValue {
                player.volume = 0.10
            }
            player.prepareToPlay()
            player.play()
        }
        catch {
            print("Error creating AVAudioPlayer: \(error)")
        }
    }

    private func uriForFile(fileName: String) -> NSURL {
        let path = Bundle.main.path(forResource: fileName, ofType: "aac")
        let fileUri: NSURL = NSURL(fileURLWithPath: path!)
        return fileUri
    }
}

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }
}

enum Sound: String {
    case greeting     = "notification_candi_discovered_soft"
    case notification = "notification_activity"
    case pop          = "notification_pop"
    case messageSent
}
