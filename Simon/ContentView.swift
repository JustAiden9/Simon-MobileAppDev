import SwiftUI

struct ContentView: View {
    @State private var colorDisplay = [
        ColorDisplay(color: .green),
        ColorDisplay(color: .red),
        ColorDisplay(color: .yellow),
        ColorDisplay(color: .blue)
    ]
    @State private var activeIndex: Int? = nil
    @State private var sequence: [Int] = [] 
    @State private var userIndex: Int = 0
    @State private var isPlayingSequence: Bool = false
    @State private var isGameActive: Bool = false
    @State private var message: String = "Tap Start to play"
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
                if isGameActive {
                    Text("Round \(max(sequence.count, 1))")
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 8) {
                    Button(action: startGame) {
                        Text(isGameActive ? "Restart" : "Start") //check if we are in game or starting game
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

    private func tile(_ i: Int) -> some View {
        colorDisplay[i]
            .opacity(activeIndex == i ? 1 : 0.4)
            .onTapGesture { handleTap(i) }
    }

    private func startGame() {
        sequence = []
        userIndex = 0
        isGameActive = true
        message = "Watch…"
        sound.playStart()
        appendRandomAndPlay()
    }

    private func appendRandomAndPlay() {
        sequence.append(Int.random(in: 0...3))
        Task { await playSequence() }
    }

    @MainActor
    private func setActive(_ i: Int?) {
        withAnimation(.easeInOut(duration: 0.22)) {
            activeIndex = i
        }
    }

    private func flashColorDisplay(index: Int) {
        setActive(index)
        sound.playColor(index: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            setActive(nil)
        }
    }

    private func handleTap(_ i: Int) {
        guard isGameActive, !isPlayingSequence, !sequence.isEmpty else { return }

        // Tap feedback
        flashColorDisplay(index: i)

        if i == sequence[userIndex] {
            userIndex += 1
            if userIndex == sequence.count {
                // Completed the round
                isPlayingSequence = true
                message = "Watch…"
                sound.playSuccess()
                userIndex = 0
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    appendRandomAndPlay()
                }
            } else {
                message = "Your turn"
            }
        } else {
            // Wrong input
            let score = max(sequence.count - 1, 0)

            // Update high score and choose sound
            var playedHighScore = false
            if score > highScore {
                highScore = score
                sound.playHighScore()
                playedHighScore = true
            }

            if !playedHighScore {
                sound.playLose()
            }

            // Mark loss state for UI
            isGameActive = false
            isPlayingSequence = false
            message = "Wrong! Tap Start"
            sequence = []
            userIndex = 0
        }
    }

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
