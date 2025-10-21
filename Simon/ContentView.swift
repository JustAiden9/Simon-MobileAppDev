import SwiftUI

struct ContentView: View {
    // Holds display views for each color tile
    @State private var colorDisplay = [
        ColorDisplay(color: .green),
        ColorDisplay(color: .red),
        ColorDisplay(color: .yellow),
        ColorDisplay(color: .blue)
    ]
    // Index of the currently highlighted tile, or nil if none
    @State private var activeIndex: Int? = nil
    // Current sequence (in terms of color indexes) player must memorize
    @State private var sequence: [Int] = [] 
    // Where in the sequence the user is currently guessing
    @State private var userIndex: Int = 0
    // True if the game is currently playing back the sequence for the user
    @State private var isPlayingSequence: Bool = false
    // Indicates if a game is running (prevents input between rounds)
    @State private var isGameActive: Bool = false
    // Shows current status message (start, watch, your turn, etc)
    @State private var message: String = "Tap Start to play"
    // Highest score persisted across launches
    @AppStorage("highScore") private var highScore: Int = 0
    // Singleton for playing sounds
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
                if isGameActive {
                    Text("Round \(max(sequence.count, 1))")
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 8) {
                    Button(action: startGame) {
                        Text(isGameActive ? "Restart" : "Start") // Shows correct label based on game state
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)

                    Text("High Score: \(highScore)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    // Returns view for a color tile, applying current highlight state and tap handling
    private func tile(_ i: Int) -> some View {
        colorDisplay[i]
            .opacity(activeIndex == i ? 1 : 0.4)
            .onTapGesture { handleTap(i) }
    }

    // Starts or restarts the game, resetting all state and beginning a new round
    private func startGame() {
        sequence = []
        userIndex = 0
        isGameActive = true
        message = "Watch…"
        sound.playStart() // Play start sound
        appendRandomAndPlay() // Add a random color and play the sequence
    }

    // Adds a random color to the sequence and begins playback
    private func appendRandomAndPlay() {
        sequence.append(Int.random(in: 0...3))
        // Use async/await to play the sequence animation without blocking main thread
        Task { await playSequence() }
    }

    // Animates the given tile as active (highlighted), optionally with animation
    @MainActor
    private func setActive(_ i: Int?) {
        withAnimation(.easeInOut(duration: 0.22)) {
            activeIndex = i
        }
    }

    // Briefly flashes a tile as feedback for taps or sequence playback
    private func flashColorDisplay(index: Int) {
        setActive(index)
        sound.playColor(index: index)
        // Reset highlight after a short delay (not awaiting, done via DispatchQueue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            setActive(nil)
        }
    }

    // Handles user tile tap: checks correctness, advances game, or ends game
    private func handleTap(_ i: Int) {
        // Only process taps if game is active, not playing sequence, and there's a sequence
        guard isGameActive, !isPlayingSequence, !sequence.isEmpty else { return }

        flashColorDisplay(index: i) // Visual & audio feedback for tap

        if i == sequence[userIndex] {
            // Correct tap
            userIndex += 1
            if userIndex == sequence.count {
                // Player finished the sequence
                isPlayingSequence = true
                message = "Watch…"
                sound.playSuccess()
                userIndex = 0
                // Pause before next round, then add new color and play
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    appendRandomAndPlay()
                }
            } else {
                // Wait for next input
                message = "Your turn"
            }
        } else {
            // Incorrect tap—end game, update high score, show message
            let score = max(sequence.count - 1, 0)

            // Only play high score sound if new record
            var playedHighScore = false
            if score > highScore {
                highScore = score
                sound.playHighScore()
                playedHighScore = true
            }

            if !playedHighScore {
                sound.playLose()
            }

            // Reset game state
            isGameActive = false
            isPlayingSequence = false
            message = "Wrong! Tap Start"
            sequence = []
            userIndex = 0
        }
    }

    // Plays the full color sequence for the user with delays and animation
    private func playSequence() async {
        isPlayingSequence = true
        userIndex = 0
        await MainActor.run { message = "Watch…" }

        for idx in sequence {
            // Animate and play sound for this tile
            await MainActor.run {
                setActive(idx)
                sound.playColor(index: idx)
            }
            // Wait so user can see/hear each tile
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run { setActive(nil) } // Remove highlight
            try? await Task.sleep(for: .milliseconds(160)) // Small gap
        }

        isPlayingSequence = false
        await MainActor.run { message = "Your turn" }
    }
}

#Preview {
    ContentView()
}
