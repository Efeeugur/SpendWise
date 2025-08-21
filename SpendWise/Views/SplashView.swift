import SwiftUI

struct SplashView: View {
    @State private var progress: CGFloat = 0.0
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var progressOpacity: Double = 0.0
    @State private var copyrightOpacity: Double = 0.0
    @State private var logoRotation: Double = 0.0
    @State private var sparkleOpacity: Double = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and title section
                    VStack(spacing: 24) {
                        // Animated logo with effects
                        ZStack {
                            // Pulsing background glow
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                                .scaleEffect(logoScale)
                                .opacity(logoOpacity)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: logoScale)
                            
                            // Rotating ring
                            Circle()
                                .stroke(Color.green.opacity(0.2), lineWidth: 4)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(logoRotation))
                                .opacity(logoOpacity)
                            
                            // Main logo
                            Image(systemName: "dollarsign.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.green)
                                .scaleEffect(logoScale)
                                .opacity(logoOpacity)
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 0)
                            
                            // Sparkle effects
                            Group {
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 6, height: 6)
                                    .offset(x: 45, y: -45)
                                    .opacity(sparkleOpacity)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5), value: sparkleOpacity)
                                
                                Circle()
                                    .fill(Color.green.opacity(0.6))
                                    .frame(width: 4, height: 4)
                                    .offset(x: -40, y: 40)
                                    .opacity(sparkleOpacity)
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.0), value: sparkleOpacity)
                                
                                Circle()
                                    .fill(Color.green.opacity(0.4))
                                    .frame(width: 3, height: 3)
                                    .offset(x: -35, y: -20)
                                    .opacity(sparkleOpacity)
                                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.5), value: sparkleOpacity)
                            }
                        }
                        
                        // App title with subtitle
                        VStack(spacing: 8) {
                            Text("SpendWise")
                                .font(.system(size: 36, weight: .bold, design: .default))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, Color.green.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(y: titleOffset)
                                .opacity(titleOpacity)
                            
                            Text("Smart expense tracking")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .offset(y: titleOffset)
                                .opacity(titleOpacity * 0.8)
                        }
                    }
                    
                    Spacer()
                    
                    // Progress section
                    VStack(spacing: 16) {
                        // Loading text with animated dots
                        HStack(spacing: 4) {
                            Text("Loading")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 4, height: 4)
                                        .opacity(progressOpacity)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                            value: progressOpacity
                                        )
                                }
                            }
                        }
                        .opacity(progressOpacity)
                        
                        // Progress bar
                        VStack(spacing: 8) {
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(height: 8)
                                    .foregroundColor(Color.gray.opacity(0.3))
                                
                                // Progress fill with gradient
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: max(0, progress * (UIScreen.main.bounds.width - 48)), height: 8)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .animation(.easeOut(duration: 0.1), value: progress)
                                
                                // Moving highlight
                                if progress > 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 16, height: 8)
                                        .blur(radius: 2)
                                        .offset(x: max(-8, (progress * (UIScreen.main.bounds.width - 48)) - 8))
                                        .animation(.easeOut(duration: 0.1), value: progress)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Progress percentage
                            Text("\(Int(progress * 100))%")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .opacity(progressOpacity)
                    }
                    .padding(.bottom, 32)
                    
                    // Copyright
                    Text("© 2024 SpendWise. All rights reserved.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .opacity(copyrightOpacity)
                        .padding(.bottom, 40)
                }
            }
            .onAppear {
                startAnimationSequence()
            }
        }
    }
    
    private func startAnimationSequence() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // Continuous logo rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            logoRotation = 360
        }
        
        // Sparkles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sparkleOpacity = 1.0
        }
        
        // Title animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }
        
        // Progress section animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                progressOpacity = 1.0
            }
        }
        
        // Copyright animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                copyrightOpacity = 1.0
            }
        }
        
        // Start progress after animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startProgressBar()
        }
    }
    
    private func startProgressBar() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            DispatchQueue.main.async {
                if progress >= 1.0 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isActive = true
                        }
                    }
                } else {
                    progress += 0.008
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
