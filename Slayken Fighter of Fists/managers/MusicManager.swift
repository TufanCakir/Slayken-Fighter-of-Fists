//
//  MusicManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

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

    // MARK: - INIT
    override init() {
        self.isMusicOn = UserDefaults.standard.bool(forKey: "isMusicOn")
        super.init()

        configureAudioSession()
        loadSongs()

        // Falls Musik aktiviert war – wieder starten
        if isMusicOn {
            Task { await playCurrentSong(fadeIn: true) }
        }
    }
}

// MARK: - Audio Session
extension MusicManager {
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ AudioSession konnte nicht gesetzt werden:", error.localizedDescription)

            // Fallback
            try? session.setCategory(.playback)
            try? session.setActive(true)
        }
    }
}

// MARK: - JSON Songs laden
extension MusicManager {
    private func loadSongs() {
        guard
            let url = Bundle.main.url(forResource: "songs", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(SongList.self, from: data)
        else {
            print("❌ songs.json NICHT gefunden oder fehlerhaft.")
            return
        }

        songs = decoded.songs

        if songs.isEmpty {
            print("❌ KEINE Songs in JSON gefunden.")
        } else {
            print("🎵 \(songs.count) Songs geladen.")
        }
    }
}

// MARK: - Toggle: Musik EIN/AUS
extension MusicManager {

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
}

// MARK: - SONG AB SPIELEN
extension MusicManager {

    private func playCurrentSong(fadeIn: Bool = false) async {
        guard isMusicOn else { return }
        guard !songs.isEmpty else { return }

        // Doppelstarts verhindern
        if let p = player, p.isPlaying {
            print("⚠️ Player läuft bereits — kein Doppelstart.")
            return
        }

        let song = songs[currentSongIndex]

        guard let url = Bundle.main.url(forResource: song.fileName, withExtension: "mp3") else {
            print("❌ MP3-Datei fehlt:", song.fileName)
            return
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.volume = fadeIn ? 0.0 : 0.6
            newPlayer.numberOfLoops = 0
            newPlayer.prepareToPlay()
            newPlayer.play()

            player = newPlayer

            if fadeIn {
                await fadeInMusic(to: 0.6)
            }

            print("🎶 Now Playing:", song.title)

        } catch {
            print("❌ Fehler beim Abspielen:", error.localizedDescription)
            await skipToNextSong()
        }
    }
}

// MARK: - FADE OUT
extension MusicManager {
    private func fadeOutAndStop() async {
        guard let player = player else { return }
        fadeTask?.cancel()

        fadeTask = Task {
            let startVolume = player.volume
            let steps: Float = 20

            for i in stride(from: 0, through: steps, by: 1) {
                guard !Task.isCancelled else { return }

                let newVolume = startVolume * (1 - Float(i) / steps)
                player.volume = max(newVolume, 0)

                try? await Task.sleep(nanoseconds: 40_000_000)
            }

            player.stop()
            self.player = nil
            print("🛑 Musik gestoppt")
        }

        await fadeTask?.value
    }
}

// MARK: - FADE IN
extension MusicManager {
    private func fadeInMusic(to target: Float) async {
        guard let player = player else { return }
        fadeTask?.cancel()

        fadeTask = Task {
            let steps: Float = 20

            for i in stride(from: 0, through: steps, by: 1) {
                guard !Task.isCancelled else { return }

                let newVolume = (Float(i) / steps) * target
                player.volume = min(newVolume, target)

                try? await Task.sleep(nanoseconds: 40_000_000)
            }

            player.volume = target
        }

        await fadeTask?.value
    }
}

// MARK: - NÄCHSTER SONG
extension MusicManager {

    private func skipToNextSong() async {
        guard !songs.isEmpty else { return }

        currentSongIndex = (currentSongIndex + 1) % songs.count

        print("⏭️ Weiter zu:", songs[currentSongIndex].title)

        await playCurrentSong(fadeIn: true)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { await skipToNextSong() }
    }
}

// MARK: - MODELS
struct SongList: Codable {
    let songs: [Song]
}

struct Song: Codable {
    let title: String
    let fileName: String // MUSS lokal in App sein
}
