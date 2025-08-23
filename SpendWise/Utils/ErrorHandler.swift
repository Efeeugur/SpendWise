import SwiftUI
import os.log

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError: Bool = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpendWise", category: "ErrorHandler")
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        logger.error("Error in \(context): \(error.localizedDescription)")
        
        let appError: AppError
        
        if let appErr = error as? AppError {
            appError = appErr
        } else {
            appError = AppError.general(error.localizedDescription)
        }
        
        currentError = appError
        isShowingError = true
        
        // Auto-dismiss non-critical errors after 3 seconds
        if appError.severity == .low {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.dismiss()
            }
        }
    }
    
    func dismiss() {
        currentError = nil
        isShowingError = false
    }
}

enum AppError: Error, Identifiable, Equatable {
    case networkError(String)
    case dataCorruption(String)
    case authenticationFailed
    case general(String)
    case performanceWarning(String)
    
    var id: String {
        switch self {
        case .networkError(let msg):
            return "network_\(msg)"
        case .dataCorruption(let msg):
            return "data_\(msg)"
        case .authenticationFailed:
            return "auth_failed"
        case .general(let msg):
            return "general_\(msg)"
        case .performanceWarning(let msg):
            return "performance_\(msg)"
        }
    }
    
    var title: String {
        switch self {
        case .networkError:
            return "Network Error"
        case .dataCorruption:
            return "Data Error"
        case .authenticationFailed:
            return "Authentication Failed"
        case .general:
            return "Error"
        case .performanceWarning:
            return "Performance Warning"
        }
    }
    
    var message: String {
        switch self {
        case .networkError(let msg):
            return msg
        case .dataCorruption(let msg):
            return msg
        case .authenticationFailed:
            return "Please check your credentials and try again."
        case .general(let msg):
            return msg
        case .performanceWarning(let msg):
            return msg
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError:
            return .medium
        case .dataCorruption:
            return .high
        case .authenticationFailed:
            return .high
        case .general:
            return .medium
        case .performanceWarning:
            return .low
        }
    }
}

enum ErrorSeverity {
    case low, medium, high
}

// MARK: - Error Display Modifier
struct ErrorAlert: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK") {
                    errorHandler.dismiss()
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func errorHandling() -> some View {
        modifier(ErrorAlert())
    }
}

// MARK: - Performance Toast
struct PerformanceToast: ViewModifier {
    @ObservedObject private var performanceManager = PerformanceManager.shared
    @State private var showToast = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if showToast {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.orange)
                            Text("Performance mode enabled")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(radius: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .padding(.top, 50)
                , alignment: .top
            )
            .onChange(of: performanceManager.isOptimizedMode) { isOptimized in
                if isOptimized {
                    withAnimation(.easeInOut) {
                        showToast = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut) {
                            showToast = false
                        }
                    }
                }
            }
    }
}

extension View {
    func performanceToast() -> some View {
        modifier(PerformanceToast())
    }
}