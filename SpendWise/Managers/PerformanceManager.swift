import SwiftUI
import Combine

@MainActor
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published private(set) var isOptimizedMode: Bool = false
    @Published private(set) var frameRate: Double = 60.0
    
    private var cancellables = Set<AnyCancellable>()
    private var frameTimer: Timer?
    
    private init() {
        setupPerformanceMonitoring()
        optimizeForDevice()
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor app state changes for performance optimization
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.enableOptimizedMode()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.disableOptimizedMode()
            }
            .store(in: &cancellables)
    }
    
    private func optimizeForDevice() {
        let device = UIDevice.current
        
        // Enable optimized mode for older devices or low power mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled || 
           device.systemName.contains("iPhone") && device.systemVersion.compare("15.0", options: .numeric) == .orderedAscending {
            isOptimizedMode = true
            frameRate = 30.0
        }
    }
    
    func enableOptimizedMode() {
        isOptimizedMode = true
        frameRate = 30.0
    }
    
    func disableOptimizedMode() {
        isOptimizedMode = false
        frameRate = 60.0
    }
    
    // Animation configuration based on performance mode
    var animationDuration: Double {
        isOptimizedMode ? 0.2 : 0.3
    }
    
    var springStiffness: Double {
        isOptimizedMode ? 300 : 400
    }
    
    var springDamping: Double {
        isOptimizedMode ? 30 : 25
    }
}

// MARK: - Performance Optimized View Modifier
struct PerformanceOptimized: ViewModifier {
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    func body(content: Content) -> some View {
        content
            .drawingGroup(opaque: true, colorMode: .nonLinear)
            .animation(
                .interpolatingSpring(
                    stiffness: performanceManager.springStiffness,
                    damping: performanceManager.springDamping
                ),
                value: performanceManager.isOptimizedMode
            )
    }
}

extension View {
    func performanceOptimized() -> some View {
        modifier(PerformanceOptimized())
    }
}

// MARK: - Lazy Loading Helper
@propertyWrapper
struct LazyState<T>: DynamicProperty {
    @State private var _value: T?
    private let initializer: () -> T
    
    init(_ initializer: @escaping () -> T) {
        self.initializer = initializer
    }
    
    var wrappedValue: T {
        get {
            if let value = _value {
                return value
            }
            let newValue = initializer()
            _value = newValue
            return newValue
        }
        nonmutating set {
            _value = newValue
        }
    }
    
    var projectedValue: Binding<T> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

// MARK: - Memory Efficient List
struct PerformantList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        if performanceManager.isOptimizedMode {
            // Use LazyVStack for better performance in optimized mode
            LazyVStack(spacing: 8) {
                ForEach(Array(data.prefix(50)), id: \.id) { item in
                    content(item)
                }
            }
        } else {
            // Use regular List for better user experience
            List(data, id: \.id) { item in
                content(item)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .listStyle(PlainListStyle())
        }
    }
}