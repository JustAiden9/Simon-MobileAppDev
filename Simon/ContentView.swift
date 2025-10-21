//
//  ContentView.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import SwiftUI

struct ContentView: View {
    // Color tiles for the game
    @State private var colorDisplay = [
        ColorDisplay(color: .green),
        ColorDisplay(color: .red),
        ColorDisplay(color: .yellow),
        ColorDisplay(color: .blue)
    ]
    // Which tile is currently lit up
    @State private var activeIndex: Int? = nil
    // The sequence of colors to remember
    @State private var sequence: [Int] = []
    // Where the player is in guessing the sequence
    @State private var userIndex: Int = 0
    // True when computer is showing the sequence
    @State private var isPlayingSequence: Bool = false
    // True when game is running
    @State private var isGameActive: Bool = false
    // Status message shown to player
    @State private var message: String = "Tap Start to play"
    // Best score ever
    @AppStorage("highScore") private var highScore: Int = 0
    @State private var showStartMenu: Bool = true
    @State private var showEndMenu: Bool = false
    @State private var finalScore: Int = 0
    @State private var isNewHighScore: Bool = false
    
    private let sound = SoundManager.shared

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Simon")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Text(message)
                    .foregroundStyle(.white.opacity(0.8))
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        tile(0)
                        tile(1)
                    }
                    HStack(spacing: 12) {
                        tile(2)
                        tile(3)
                    }
                }
                .padding()
                // Show current round number
                if isGameActive {
                    Text("Round \(max(sequence.count, 1))")
                        .foregroundStyle(.white.opacity(0.7))
                }
                VStack(spacing: 8) {
                    Button(action: startGame) {
                        Text(isGameActive ? "Restart" : "Start")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15), in: .capsule)
                    }
                    .foregroundStyle(.white)
                    Text("High Score: \(highScore)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .padding()
            .blur(radius: (showStartMenu || showEndMenu) ? 10 : 0)
            // Start menu overlay
            if showStartMenu {
                VStack(spacing: 24) {
                    Text("Simon")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Match the pattern!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("High Score: \(highScore)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Button(action: {
                        showStartMenu = false
                        startGame()
                    }) {
                        Text("Start Game")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.2), in: .capsule)
                    }
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.40))
            }
            // End menu overlay
            if showEndMenu {
                VStack(spacing: 24) {
                    Text(isNewHighScore ? "New High Score!" : "Game Over")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(isNewHighScore ? .yellow : .white)
                    
                    Text("Score: \(finalScore)")
                        .font(.title)
                        .foregroundStyle(.white)
                    
                    Text("High Score: \(highScore)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Button(action: {
                        showEndMenu = false
                        startGame()
                    }) {
                        Text("Play Again")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.2), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.40))
            }
        }
        .preferredColorScheme(.dark)
    }

    // Create a tile view with highlight and tap handling
    private func tile(_ i: Int) -> some View {
        colorDisplay[i]
            .opacity(activeIndex == i ? 1 : 0.4)
            .onTapGesture { handleTap(i) }
    }

    // Start a new game
    private func startGame() {
        sequence = []
        userIndex = 0
        isGameActive = true
        message = "Watch…"
        sound.playStart()
        appendRandomAndPlay()
    }

    // Add random color to sequence and play it
    private func appendRandomAndPlay() {
        sequence.append(Int.random(in: 0...3))
        Task { await playSequence() }
    }

    // Light up a tile
    @MainActor
    private func setActive(_ i: Int?) {
        withAnimation(.easeInOut(duration: 0.22)) {
            activeIndex = i
        }
    }

    // Flash a tile with sound
    private func flashColorDisplay(index: Int) {
        setActive(index)
        sound.playColor(index: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            setActive(nil)
        }
    }

    // Handle player tapping a tile
    private func handleTap(_ i: Int) {
        guard isGameActive, !isPlayingSequence, !sequence.isEmpty else { return }

        flashColorDisplay(index: i)

        if i == sequence[userIndex] {
            // Correct tile
            userIndex += 1
            if userIndex == sequence.count {
                // Finished round
                isPlayingSequence = true
                message = "Watch…"
                sound.playSuccess()
                userIndex = 0
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    appendRandomAndPlay()
                }
            } else {
                // Keep going
                message = "Your turn"
            }
        } else {
            // Wrong tile - game over
            let score = max(sequence.count - 1, 0)
            finalScore = score
            
            if score > highScore {
                highScore = score
                isNewHighScore = true
                sound.playHighScore()
            } else {
                isNewHighScore = false
                sound.playLose()
            }

            isGameActive = false
            isPlayingSequence = false
            message = "Wrong! Tap Start"
            sequence = []
            userIndex = 0
            
            // Show end menu
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showEndMenu = true
            }
        }
    }

    // Play the full sequence to the player
    private func playSequence() async {
        isPlayingSequence = true
        userIndex = 0
        await MainActor.run { message = "Watch…" }

        for idx in sequence {
            await MainActor.run {
                setActive(idx)
                sound.playColor(index: idx)
            }
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run { setActive(nil) }
            try? await Task.sleep(for: .milliseconds(160))
        }

        isPlayingSequence = false
        await MainActor.run { message = "Your turn" }
    }
}

#Preview {
    ContentView()
}
