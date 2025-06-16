import SwiftUI
import CoreHaptics

struct MainInteractionView: View {
    @State private var lightIntensity: Double = 0.0
    @State private var isRevealed = false
    @State private var lastHapticTime: TimeInterval = 0
    @State private var engine: CHHapticEngine?
    @State private var isLongPressing = false
    @State private var lightPosition: CGPoint = .zero
    @State private var showInitialHint = true
    @State private var spreadRadius: CGFloat = 150
    @State private var isSpreading = false
    @State private var isDarkMode = true
    @State private var isTouching = false
    
    // Constants
    private let hapticRateLimit: TimeInterval = 1.0 / 32.0 // 32Hz rate limit
    private let longPressDuration: TimeInterval = 0.5
    private let hintDisplayDuration: TimeInterval = 3.0
    private let hintRevealThreshold: Double = 0.7
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(isDarkMode ? .black : .white).edgesIgnoringSafeArea(.all)
                    .opacity(isSpreading ? 0 : 1)
                
                // Main content
                VStack {
                    if isRevealed {
                        VStack {
                            Text("Hello!")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                                .transition(.opacity)
                            Text("Tap here then scroll around")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .transition(.opacity)
                        }
                    } else {
                        if showInitialHint || isLongPressing {
                            Text(isLongPressing ? "Hey! Long Press \nTo reveal something" : "Tap and explore around")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .transition(.opacity)
                                .opacity(isDarkMode ? (showInitialHint ? 1 : (lightIntensity > hintRevealThreshold ? 1 : 0)) : 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Candle-like light effect
                if isDarkMode {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(lightIntensity),
                            Color.white.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: isSpreading ? spreadRadius : 150
                    )
                    .frame(width: isSpreading ? geometry.size.width * 2 : 300, height: isSpreading ? geometry.size.height * 2 : 300)
                    .position(lightPosition)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                    .opacity(isTouching ? 1 : 0)
                }

                // Toggle button (only visible in light mode)
                if isDarkMode {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                resetStates()
                            }) {
//                                Image(systemName: "lightbulb.fill"
                                    .font(.system(size: 24))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                    )
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isDarkMode else { return }
                        if !isTouching {
                            isTouching = true
                           SoundManager.shared.playTorchOn()
                        }
                        lightPosition = value.location
                        let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                        let distance = sqrt(pow(value.location.x - center.x, 2) + pow(value.location.y - center.y, 2))
                        let maxDistance = min(geometry.size.width, geometry.size.height) / 2
                        
                        // Calculate intensity based on distance from center
                        lightIntensity = max(0.3, 1.0 - (distance / maxDistance))
                        
                        // Throttle haptic feedback
                        let currentTime = CACurrentMediaTime()
                        if currentTime - lastHapticTime >= hapticRateLimit {
                            triggerHapticFeedback(intensity: lightIntensity)
                            lastHapticTime = currentTime
                        }
                    }
                    .onEnded { _ in
                        guard isDarkMode else { return }
                        isTouching = false
                        lightIntensity = 0
                        SoundManager.shared.playTorchOff()
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: longPressDuration)
                    .onChanged { _ in
                        guard isDarkMode else { return }
                        isLongPressing = true
                    }
                    .onEnded { _ in
                        guard isDarkMode else { return }
                        isLongPressing = false
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            isRevealed = true
                            lightIntensity = 1.0
                            isSpreading = true
                            spreadRadius = max(geometry.size.width, geometry.size.height)
                        }
                        triggerHapticFeedback(intensity: 1.0)
                        SoundManager.shared.playWelcome()
                    }
            )
        }
        .onAppear {
            prepareHaptics()
            // Ensure initial hint is shown
            showInitialHint = true
            
            // Hide initial hint after specified duration
            DispatchQueue.main.asyncAfter(deadline: .now() + hintDisplayDuration) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showInitialHint = false
                }
            }
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Reset the engine if it stops
            engine?.resetHandler = { [weak engine] in
                do {
                    try engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    private func triggerHapticFeedback(intensity: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.5))
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParameter, sharpnessParameter], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
    
    private func resetStates() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isRevealed = false
            isSpreading = false
            spreadRadius = 150
            lightIntensity = 0
            isTouching = false
            isLongPressing = false
            showInitialHint = true
//            isDarkMode = true
            
            // Hide hint after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + hintDisplayDuration) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showInitialHint = false
                }
            }
        }
        
        // Play reset sound
        SoundManager.shared.playTorchOff()
        triggerHapticFeedback(intensity: 0.5)
    }
}

#Preview {
    MainInteractionView()
} 
