//
//  SoundManager.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import Foundation
import AVFoundation // is how apple allows apps like their clock app to have alarms with sounds

final class SoundManager: NSObject, AVAudioPlayerDelegate {
    // Provides one shared instance of SoundManager for the whole app. What that means is that I am allowed to use this SoundManager.swift anywhere in the app
    static let shared = SoundManager()
    // Keeps track of all currently playing sounds, so they aren't stopped early.
    private var players: [AVAudioPlayer] = []
    // Loads and plays a sound effect given its file name. It searches for Start.wav for example
    // Handles setting up the audio player and starting playback.
    func play(name: String, ext: String = "wav", subdirectory: String? = "sounds", volume: Float = 1.0) {
        // Try to find the sound file in a subdirectory if one is provided
        var url: URL?
        if let sub = subdirectory {
            url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub)
        }
        // If not found in a subdirectory, try to find the sound in the main bundle
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: ext)
        }
        // If the sound file can't be found, exit the function
        guard let url else { return }
        // Try to create an audio player with the sound file
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = volume
            player.delegate = self
            // Store the player so the sound doesn't stop immediately
            players.append(player)
            // Actually start playing the sound
            player.play()
        }
    }
    
    // Plays the sound for a colored tile (0-3)
    func playColor(index: Int) {
        play(name: "\(index)", subdirectory: nil)
    }
    // Plays the sound effect when the game starts
    func playStart() {
        play(name: "Start")
    }
    // Plays the sound effect for a correct sequence
    func playSuccess() {
        play(name: "success")
    }
    // Plays the sound effect when the player loses
    func playLose() {
        play(name: "Lose")
    }
    // Plays the sound effect for a new high score
    func playHighScore() {
        play(name: "HighScore")
    }
}

