import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var torchOnSound: AVAudioPlayer?
    private var torchOffSound: AVAudioPlayer?
    private var welcomeSound: AVAudioPlayer?
    private var doorOpenSound: AVAudioPlayer?
    private var doorCloseSound: AVAudioPlayer?
    
    // Volume levels (0.0 to 1.0)
    private let torchVolume: Float = 0.3  // 30% volume for torch sounds
    private let welcomeVolume: Float = 0.5 // 50% volume for welcome sound
    private let doorVolume: Float = 0.4   // 40% volume for door sounds
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // Load torch sounds
        if let torchOnURL = Bundle.main.url(forResource: "torch_on", withExtension: "mp3") {
            torchOnSound = try? AVAudioPlayer(contentsOf: torchOnURL)
            torchOnSound?.prepareToPlay()
            torchOnSound?.volume = torchVolume
        }
        
        if let torchOffURL = Bundle.main.url(forResource: "torch_off", withExtension: "mp3") {
            torchOffSound = try? AVAudioPlayer(contentsOf: torchOffURL)
            torchOffSound?.prepareToPlay()
            torchOffSound?.volume = torchVolume
        }
        
        // Load welcome sound
        if let welcomeURL = Bundle.main.url(forResource: "welcome", withExtension: "mp3") {
            welcomeSound = try? AVAudioPlayer(contentsOf: welcomeURL)
            welcomeSound?.prepareToPlay()
            welcomeSound?.volume = welcomeVolume
        }
        
        // Load door sounds
        if let doorOpenURL = Bundle.main.url(forResource: "door_open", withExtension: "mp3") {
            doorOpenSound = try? AVAudioPlayer(contentsOf: doorOpenURL)
            doorOpenSound?.prepareToPlay()
            doorOpenSound?.volume = doorVolume
        }
        
        if let doorCloseURL = Bundle.main.url(forResource: "door_close", withExtension: "mp3") {
            doorCloseSound = try? AVAudioPlayer(contentsOf: doorCloseURL)
            doorCloseSound?.prepareToPlay()
            doorCloseSound?.volume = doorVolume
        }
    }
    
    func playTorchOn() {
        // Stop any playing torch sounds first
        torchOffSound?.stop()
        torchOnSound?.currentTime = 0
        torchOnSound?.play()
    }
    
    func playTorchOff() {
        // Stop any playing torch sounds first
        torchOnSound?.stop()
        torchOffSound?.currentTime = 0
        torchOffSound?.play()
    }
    
    func playWelcome() {
        welcomeSound?.currentTime = 0
        welcomeSound?.play()
    }
    
    func playDoorOpen() {
        doorCloseSound?.stop()
        doorOpenSound?.currentTime = 0
        doorOpenSound?.play()
    }
    
    func playDoorClose() {
        doorOpenSound?.stop()
        doorCloseSound?.currentTime = 0
        doorCloseSound?.play()
    }
    
    func stopAllSounds() {
        torchOnSound?.stop()
        torchOffSound?.stop()
        welcomeSound?.stop()
        doorOpenSound?.stop()
        doorCloseSound?.stop()
    }
    
    // Function to adjust volume levels if needed
    func setTorchVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        torchOnSound?.volume = clampedVolume
        torchOffSound?.volume = clampedVolume
    }
    
    func setWelcomeVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        welcomeSound?.volume = clampedVolume
    }
    
    func setDoorVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        doorOpenSound?.volume = clampedVolume
        doorCloseSound?.volume = clampedVolume
    }
} 
