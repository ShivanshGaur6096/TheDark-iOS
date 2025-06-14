import SwiftUI
import CoreHaptics

struct SplashScreenView: View {
    @State private var topTextOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var bottomTextOffset: CGFloat = UIScreen.main.bounds.width
    @State private var engine: CHHapticEngine?
    @State private var isAnimating = false
    @State private var isOverlapping = false
    @Binding var showSplash: Bool
    
    // Animation timing
    let fastDuration: Double = 3.0
    let slowDuration: Double = 0.7
    let pauseDuration: Double = 1.0
    let totalDuration: Double = 4.7 // Single round: fast + slow + pause
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Welcome To")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: topTextOffset)
                
                Text("The Dark")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: bottomTextOffset)
            }
        }
        .onAppear {
            setupHaptics()
            startAnimation()
        }
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // Play door open sound at the start
        SoundManager.shared.playDoorOpen()
        
        // Start buzzing haptic for initial movement
        playBuzzingHaptic(duration: fastDuration)
        
        // Single round animation
        animateRound()
        
        // Transition to main view after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation {
                showSplash = false
            }
        }
    }
    
    private func animateRound() {
        // Reset to starting positions
        topTextOffset = -UIScreen.main.bounds.width
        bottomTextOffset = UIScreen.main.bounds.width
        
        // Fast movement to center
        withAnimation(.easeInOut(duration: fastDuration)) {
            topTextOffset = 0
            bottomTextOffset = 0
        }
        
        // Overlap point (slow down and pause)
        DispatchQueue.main.asyncAfter(deadline: .now() + fastDuration) {
            withAnimation(.easeInOut(duration: slowDuration)) {
                // Slow down animation
            }
            // Hammer haptic when texts meet
            playHammerHaptic()
            
            // Pause at center
            DispatchQueue.main.asyncAfter(deadline: .now() + slowDuration) {
                // Keep texts centered during pause
                topTextOffset = 0
                bottomTextOffset = 0
                
                // After pause, continue movement
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                    // Play door close sound before continuing
                    SoundManager.shared.playDoorClose()
                    
                    // Hammer haptic before continuing
                    playHammerHaptic()
                    // Start buzzing haptic for exit movement
                    playBuzzingHaptic(duration: fastDuration)
                    
                    withAnimation(.easeInOut(duration: fastDuration)) {
                        topTextOffset = UIScreen.main.bounds.width
                        bottomTextOffset = -UIScreen.main.bounds.width
                    }
                }
            }
        }
    }
    
    private func playBuzzingHaptic(duration: Double) {
        guard let engine = engine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: duration)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
    
    private func playHammerHaptic() {
        guard let engine = engine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
} 
