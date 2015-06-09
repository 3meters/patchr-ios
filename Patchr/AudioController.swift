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
    
    var player: AVAudioPlayer! = nil
    
    func play(sound: String) {
        player = AVAudioPlayer(contentsOfURL: self.uriForFile(sound), error: nil)
        player.prepareToPlay()
        player.play()
    }
    
    private func uriForFile(fileName: String) -> NSURL {
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType:"aac")
        let fileUri: NSURL = NSURL(fileURLWithPath: path!)!
        return fileUri
    }
}

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        self.player = nil
    }
}

enum Sound: String {
    case greeting       = "notification_candi_discovered_soft"
    case notification   = "notification_activity"
    case pop            = "notification_pop"
}
