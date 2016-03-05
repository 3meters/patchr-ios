//
//  AudioController.swift
//  Patchr
//
//  Created by Jay Massena on 5/25/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import AVFoundation

class AudioController: NSObject {
    
    static let instance = AudioController()
	static let chirpSound: SystemSoundID = createChirpSound()
	
	var player: AVAudioPlayer! = nil
    
    func play(sound: String) {
        do {
            player = try AVAudioPlayer(contentsOfURL: self.uriForFile(sound), fileTypeHint: nil)
            player.prepareToPlay()
            player.play()
        }
        catch {
            print("Error creating AVAudioPlayer: \(error)")
        }
    }
    
    private func uriForFile(fileName: String) -> NSURL {
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType:"aac")
        let fileUri: NSURL = NSURL(fileURLWithPath: path!)
        return fileUri
    }
}

func createChirpSound() -> SystemSoundID {
	var soundID: SystemSoundID = 0
	let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "chirp", "caf", nil)
	AudioServicesCreateSystemSoundID(soundURL, &soundID)
	return soundID
}

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }
}

enum Sound: String {
    case greeting       = "notification_candi_discovered_soft"
    case notification   = "notification_activity"
    case pop            = "notification_pop"
}
