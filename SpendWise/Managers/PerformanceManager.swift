import SwiftUI
import Combine

@MainActor
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published private(set) var isOptimizedMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPerformanceMonitoring()
        optimizeForDevice()
    }
    
    private func setupPerformanceMonitoring() {
        // Enable optimized mode when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isOptimizedMode = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isOptimizedMode = false
            }
            .store(in: &cancellables)
    }
    
    private func optimizeForDevice() {
        // Enable optimized mode for Low Power Mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            isOptimizedMode = true
        }
    }
    
    // Animation configuration based on performance mode
    var animationDuration: Double {
        isOptimizedMode ? 0.2 : 0.3
    }
}