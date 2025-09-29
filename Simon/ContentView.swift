import SwiftUI

struct ContentView: View {
    @State private var colorDisplay = [
        ColorDisplay(color: .green),
        ColorDisplay(color: .red),
        ColorDisplay(color: .yellow),
        ColorDisplay(color: .blue)
    ]
    @State private var flash = [false, false, false, false]
    @State private var sequence: [Int] = [] 
    @State private var userIndex: Int = 0
    @State private var isPlayingSequence: Bool = false
    @State private var isGameActive: Bool = false
    @State private var message: String = "Tap Start to play"
    @State private var justLost: Bool = false
    @State private var lastScore: Int? = nil
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

                Group {
                    if justLost {
                        VStack(spacing: 4) {
                            Text("Wrong! Score: \(lastScore ?? 0)")
                            Text("Tap Start")
                        }
                    } else {
                        Text(message)
                    }
                }
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

                    if !justLost {
                        Text("High Score: \(highScore)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
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
            .opacity(flash[i] ? 1 : 0.4)
            .onTapGesture { handleTap(i) }
    }

    private func startGame() {
        sequence = []
        userIndex = 0
        isGameActive = true
        message = "Watch…"
        justLost = false
        lastScore = nil
        sound.playStart()
        appendRandomAndPlay()
    }

    private func appendRandomAndPlay() {
        sequence.append(Int.random(in: 0...3))
        Task { await playSequence() }
    }

    @MainActor
    private func setFlash(_ i: Int, _ value: Bool) {
        withAnimation(.easeInOut(duration: 0.22)) {
            flash[i] = value
        }
    }

    private func flashColorDisplay(index: Int) {
        setFlash(index, true)
        sound.playColor(index: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            setFlash(index, false)
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
                message = "Nice! Watch…"
                sound.playSuccess()
                userIndex = 0
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
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
            justLost = true
            lastScore = score

            isGameActive = false
            isPlayingSequence = false
            message = "Wrong! Score: \(score). Tap Start"
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
                setFlash(idx, true)
                sound.playColor(index: idx)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run { setFlash(idx, false) }
            try? await Task.sleep(nanoseconds: 160_000_000)
        }

        isPlayingSequence = false
        await MainActor.run { message = "Your turn" }
    }
}

#Preview {
    ContentView()
}
