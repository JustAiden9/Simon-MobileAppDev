//
//  SoundManager.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import Foundation
import AVFoundation

final class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    private var players: [AVAudioPlayer] = []
    
    // Play any sound file
    func play(name: String, ext: String = "wav", subdirectory: String? = "sounds", volume: Float = 1.0) {
        var url: URL?
        if let sub = subdirectory {
            url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub)
        }
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: ext)
        }
        guard let url else { return }
        
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = volume
            player.delegate = self
            players.append(player)
            player.play()
        }
    }
    func playColor(index: Int) {
        play(name: "\(index)", subdirectory: nil)
    }
    func playStart() {
        play(name: "Start")
    }
    func playSuccess() {
        play(name: "success")
    }
    func playLose() {
        play(name: "Lose")
    }
    func playHighScore() {
        play(name: "HighScore")
    }
}
