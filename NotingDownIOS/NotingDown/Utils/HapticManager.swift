import SwiftUI
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// Custom button style with haptic feedback
struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    init(hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.hapticStyle = hapticStyle
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticManager.shared.impact(hapticStyle)
                }
            }
    }
}

// Enhanced animations
struct AnimationPresets {
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.15)
    static let slow = Animation.easeInOut(duration: 0.5)
}

// Custom transition for note cards
struct SlideInTransition: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 50)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(AnimationPresets.bouncy.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideInTransition(delay: Double = 0) -> some View {
        modifier(SlideInTransition(delay: delay))
    }
    
    func hapticButton(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        buttonStyle(HapticButtonStyle(hapticStyle: style))
    }
}
