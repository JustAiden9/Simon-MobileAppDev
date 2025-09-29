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

    private var players: [AVAudioPlayer] = [] // retain while playing
    private var sessionConfigured = false

    private override init() {
        super.init()
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            // Ambient so it respects the Silent switch and mixes with other audio
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            sessionConfigured = true
        } catch {
            // If the session fails, we can still attempt to play; ignore errors
        }
    }

    func play(name: String, ext: String = "wav", subdirectory: String? = "sounds", volume: Float = 1.0) {
        configureSessionIfNeeded()
        let bundle = Bundle.main

        var url: URL? = nil
        if let sub = subdirectory {
            url = bundle.url(forResource: name, withExtension: ext, subdirectory: sub)
        }
        if url == nil {
            url = bundle.url(forResource: name, withExtension: ext)
        }
        guard let url else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.delegate = self
            players.append(player)
            player.play()
        } catch {
            // Ignore playback errors to avoid disrupting gameplay
        }
    }

    // MARK: - Convenience

    func playColor(index: Int) {
        play(name: "\(index)")
    }

    func playStart() {
        play(name: "start")
    }

    func playSuccess() {
        play(name: "success")
    }

    func playWrong() {
        if resourceExists("wrong") { play(name: "wrong"); return }
        if resourceExists("fail") { play(name: "fail"); return }
        if resourceExists("error") { play(name: "error"); return }
        play(name: "4")
    }

    func playLose() {
        if resourceExists("lose") { play(name: "lose"); return }
        if resourceExists("gameover") { play(name: "gameover"); return }
        playWrong()
    }

    func playHighScore() {
        if resourceExists("highscore") { play(name: "highscore"); return }
        if resourceExists("newhighscore") { play(name: "newhighscore"); return }
        playSuccess()
    }

    private func resourceExists(_ name: String, ext: String = "wav", subdirectory: String? = "sounds") -> Bool {
        let b = Bundle.main
        if let sub = subdirectory, b.url(forResource: name, withExtension: ext, subdirectory: sub) != nil { return true }
        return b.url(forResource: name, withExtension: ext) != nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        players.removeAll { $0 === player }
    }
}
