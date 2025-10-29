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
    @State private var message: String = "testValue"
    // Best score ever
    @State private var showStartMenu: Bool = true
    @State private var showEndMenu: Bool = false
    @State private var finalScore: Int = 0
    @State private var isNewHighScore: Bool = false
    @AppStorage("highScore") private var highScore: Int = 0
    
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
    
    //START OF FUNCTIONS
    // Creates a single colored tile for the game.
    // Highlights the tile if it is currently active, and handles taps by calling the tap handler.
    private func tile(_ i: Int) -> some View {
        // Pick the correct color tile from the array
        colorDisplay[i]
            .opacity(activeIndex == i ? 1 : 0.4)
            .onTapGesture { handleTap(i) }
    }

    // Starts a new Simon game.
    // Resets the sequence, sets the game as active, updates the message, and plays the start sound.
    private func startGame() {
        // Reset the sequence to start a new game
        sequence = []
        userIndex = 0
        isGameActive = true
        message = "Watch…"
        sound.playStart()
        RandomAndPlay()
    }

    // Adds a random color to the sequence, then plays the full sequence for the player to watch.
    private func RandomAndPlay() {
        // Add a new random color (represented by a number 0-3) to the sequence
        sequence.append(Int.random(in: 0...3))
        Task { await playSequence() }
    }

    // Changes which tile is currently highlighted ("lit up") on the board, with animation.
    // If nil is passed, no tile is highlighted.
    @MainActor
    private func setActive(_ i: Int?) {
        // Highlight the tile with a smooth animation
        withAnimation(.easeInOut(duration: 0.22)) {
            activeIndex = i
        }
    }

    // Temporarily flashes a tile and plays its sound.
    // The highlight turns off automatically after a quick pause.
    private func flashColorDisplay(index: Int) { //index: Int = the color that we stated at the very top
        setActive(index) // < color
        sound.playColor(index: index) // color corresponding to sound color
        // Turn off the highlight shortly after lighting up the tile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            setActive(nil)
        }
    }

    // Handles when the player taps a tile.
    // Checks if the tap is correct; if so, moves to the next step or round. If wrong, ends the game and shows the end menu.
    private func handleTap(_ i: Int) {
        guard isGameActive, !isPlayingSequence, !sequence.isEmpty else { return } // Guard is a easy way to tell your code if all of these are true you can continue. It is like if or else but it allows me to shrink the if/else code down.
        flashColorDisplay(index: i)
        // 'userIndex' tracks how many correct taps the player has made so far
        // 'sequence[userIndex]' gets the expected color at the current step
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
                    RandomAndPlay()
                }
            } else {
                // Keep going
                message = "Your turn"
            }
        } else {
            // Wrong tile - game over
            // Calculate score: subtract 1 since the last tap was wrong; never go below 0
            let score = max(sequence.count - 1, 0)
            finalScore = score
            if score > highScore {
                highScore = score
                isNewHighScore = true
                sound.playHighScore()
            } else {
                isNewHighScore = false // if your current score is lower than highscore it will not update
                sound.playLose()
            }
            isGameActive = false
            isPlayingSequence = false
            message = "Wrong! Tap Start"
            sequence = []
            userIndex = 0 // reset colors
            
            // Show end menu
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showEndMenu = true
            }
        }
    }

    // Shows the current color sequence to the player by lighting up each tile one after another, with sounds.
    // Runs asynchronously to handle the timing of each step.
    private func playSequence() async {
        isPlayingSequence = true
        userIndex = 0 // start at 0
        await MainActor.run { message = "Watch…" }

        // 'idx' is the index of the tile (0-3) to light up at this step in the sequence
        for idx in sequence {
            await MainActor.run {
                setActive(idx)
                sound.playColor(index: idx)
            }
            try? await Task.sleep(for: .milliseconds(300)) // we have to wait to allow the human to see the colors, if we did not have this the app would go to fast and we would not be able to see the colors. 
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
