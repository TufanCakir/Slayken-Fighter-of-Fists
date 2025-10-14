import Foundation
import AVFoundation
import Combine

@MainActor
final class MusicManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published
    @Published var isMusicOn: Bool {
        didSet { Task { await handleMusicToggle() } }
    }

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var currentSongIndex = 0
    private var songs: [Song] = []
    private var fadeTask: Task<Void, Never>?

    // MARK: - Init
    override init() {
        self.isMusicOn = UserDefaults.standard.bool(forKey: "isMusicOn")
        super.init()
        configureAudioSession()
        loadSongs()
        // Kein Autostart mehr (verhindert Doppelplayback)
    }

    // MARK: - Audio Session Setup
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ AudioSession error:", error.localizedDescription)
        }
    }

    // MARK: - Songdaten laden
    private func loadSongs() {
        guard
            let url = Bundle.main.url(forResource: "songs", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(SongList.self, from: data)
        else {
            print("⚠️ Keine Songs gefunden oder JSON fehlerhaft.")
            return
        }
        songs = decoded.songs
    }

    // MARK: - Musik Toggle (On/Off)
    func handleMusicToggle() async {
        UserDefaults.standard.set(isMusicOn, forKey: "isMusicOn")

        if isMusicOn {
            print("🎵 Musik aktiviert")
            await playCurrentSong(fadeIn: true)
        } else {
            print("🔇 Musik deaktiviert")
            await fadeOutAndStop()
        }
    }

    // MARK: - Song abspielen
    private func playCurrentSong(fadeIn: Bool = false) async {
        guard isMusicOn, !songs.isEmpty else { return }

        // Doppelstart verhindern
        if let p = player, p.isPlaying {
            print("⚠️ Player läuft bereits, kein erneuter Start.")
            return
        }

        let song = songs[currentSongIndex]
        guard let url = URL(string: song.url) else {
            print("❌ Ungültige URL: \(song.url)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let newPlayer = try AVAudioPlayer(data: data)
            newPlayer.delegate = self
            newPlayer.numberOfLoops = 0
            newPlayer.volume = fadeIn ? 0.0 : 0.6
            newPlayer.prepareToPlay()
            newPlayer.play()

            player = newPlayer
            if fadeIn { await fadeInMusic(to: 0.6) }

            print("🎶 Now playing:", song.title)
        } catch {
            print("❌ Fehler beim Abspielen:", error.localizedDescription)
            await skipToNextSong()
        }
    }

    // MARK: - Smooth Fade-Out
    private func fadeOutAndStop() async {
        guard let player = player else { return }
        fadeTask?.cancel()

        fadeTask = Task {
            for volume in stride(from: player.volume, through: 0, by: -0.05) {
                guard !Task.isCancelled else { return }
                player.volume = max(volume, 0)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            player.stop()
            self.player = nil
            print("🛑 Musik gestoppt")
        }
        await fadeTask?.value
    }

    // MARK: - Fade-In Effekt
    private func fadeInMusic(to targetVolume: Float) async {
        guard let player = player else { return }
        fadeTask?.cancel()

        fadeTask = Task {
            for volume in stride(from: player.volume, to: targetVolume, by: 0.05) {
                guard !Task.isCancelled else { return }
                player.volume = min(volume, targetVolume)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            player.volume = targetVolume
        }
        await fadeTask?.value
    }

    // MARK: - Nächster Song
    private func skipToNextSong() async {
        guard !songs.isEmpty else { return }
        currentSongIndex = (currentSongIndex + 1) % songs.count
        print("⏭️ Überspringe zu:", songs[currentSongIndex].title)
        await playCurrentSong(fadeIn: true)
    }

    // MARK: - Delegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { await skipToNextSong() }
    }
}

// MARK: - Models
struct SongList: Codable {
    let songs: [Song]
}

struct Song: Codable {
    let title: String
    let url: String
}
