import Foundation
@preconcurrency import AVFoundation
import Combine

final class MusicManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published
    @Published var isMusicOn: Bool {
        didSet {
            UserDefaults.standard.set(isMusicOn, forKey: "isMusicOn")
            updateMusicState()
        }
    }

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var currentSongIndex = 0
    private var songs: [Song] = []
    private var fadeTimer: Timer?
    private var isFading = false

    // MARK: - Init
    override init() {
        self.isMusicOn = UserDefaults.standard.bool(forKey: "isMusicOn")
        super.init()
        configureAudioSession()
        loadSongs()

        // Zufälligen Song beim Start wählen
        if !songs.isEmpty {
            currentSongIndex = Int.random(in: 0..<songs.count)
        }

        // Falls Musik aktiviert ist → sofort starten
        if isMusicOn {
            Task { await playCurrentSong(fadeIn: true) }
        }
    }

    // MARK: - Audio Session Setup
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ AudioSession konnte nicht aktiviert werden: \(error.localizedDescription)")
        }
    }

    // MARK: - Lade Songs (lokal)
    private func loadSongs() {
        guard let url = Bundle.main.url(forResource: "songs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SongList.self, from: data)
        else {
            print("⚠️ Fehler: songs.json konnte nicht geladen werden.")
            return
        }
        songs = decoded.songs
    }

    // MARK: - Öffentliche Steuerung
    func toggleMusic() {
        isMusicOn.toggle()
    }

    // MARK: - Interne Steuerung
    private func updateMusicState() {
        if isMusicOn {
            Task { await playCurrentSong(fadeIn: true) }
        } else {
            fadeOutAndStop()
        }
    }

    // MARK: - Song abspielen (asynchron via URLSession)
    private func playCurrentSong(fadeIn: Bool = false) async {
        guard isMusicOn, !songs.isEmpty else { return }
        let song = songs[currentSongIndex]

        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: song.url)!)
            try await MainActor.run {
                self.player = try AVAudioPlayer(data: data)
                self.player?.delegate = self
                self.player?.volume = fadeIn ? 0.0 : 0.6
                self.player?.prepareToPlay()
                self.player?.play()

                if fadeIn {
                    self.fadeIn(to: 0.6)
                }

                print("🎵 Now Playing: \(song.title)")
            }
        } catch {
            print("❌ Fehler beim Laden/Abspielen: \(error.localizedDescription)")
        }
    }

    // MARK: - Nächster Song automatisch
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard isMusicOn, !songs.isEmpty else { return }

        currentSongIndex = (currentSongIndex + 1) % songs.count
        fadeOutAndPlayNext()
    }

    // MARK: - Fade-Out + Stop
    private func fadeOutAndStop() {
        guard !isFading, let player = player else { return }
        isFading = true

        var volume = player.volume
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if volume > 0.05 {
                volume -= 0.05
                player.volume = max(volume, 0)
            } else {
                timer.invalidate()
                player.stop()
                self.player = nil
                self.isFading = false
            }
        }
    }

    // MARK: - Fade-In
    private func fadeIn(to target: Float) {
        guard let player = player else { return }
        fadeTimer?.invalidate()

        var volume = player.volume
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if volume < target {
                volume += 0.05
                player.volume = min(volume, target)
            } else {
                timer.invalidate()
            }
        }
    }

    // MARK: - Fade-Out + Next Song
    private func fadeOutAndPlayNext() {
        guard let player = player else { return }

        var volume = player.volume
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if volume > 0.05 {
                volume -= 0.05
                player.volume = max(volume, 0)
            } else {
                timer.invalidate()
                player.stop()
                self.player = nil

                // Nächster Song mit sanftem Fade-In (asynchron)
                Task { await self.playCurrentSong(fadeIn: true) }
            }
        }
    }
}

// MARK: - Models
struct Song: Codable {
    let title: String
    let url: String
}

struct SongList: Codable {
    let songs: [Song]
}
