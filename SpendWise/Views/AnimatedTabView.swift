import SwiftUI

@MainActor

struct AnimatedTabView: View {
    @Binding var selectedTab: Int
    @Binding var incomes: [Income]
    @Binding var expenses: [Expense]
    @Binding var user: User?
    @Binding var userId: String
    @Binding var showAuthSheet: Bool
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            TabView(selection: $selectedTab) {
                NavigationStack {
                    IncomesView(incomes: $incomes, userId: $userId)
                        .navigationTitle("Incomes".localized)
                }
                .tag(0)
                
                NavigationStack {
                    ExpensesView(expenses: $expenses, userId: $userId)
                        .navigationTitle("Expenses".localized)
                }
                .tag(1)
                
                NavigationStack {
                    SummaryView(incomes: $incomes, expenses: $expenses)
                        .navigationTitle("Summary".localized)
                }
                .tag(2)
                
                NavigationStack {
                    ProfileSettingsView(user: $user, isAuthSheetPresented: $showAuthSheet)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom animated tab bar
            CustomTabBar(selectedTab: $selectedTab, hapticFeedback: hapticFeedback)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let hapticFeedback: UIImpactFeedbackGenerator
    
    @State private var tabBarOffset: CGFloat = 0
    @State private var bounceEffect: Bool = false
    @Namespace private var tabIndicator
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    private let tabs = [
        TabItem(id: 0, title: "Incomes".localized, icon: "arrow.up.circle"),
        TabItem(id: 1, title: "Expenses".localized, icon: "arrow.down.circle"),
        TabItem(id: 2, title: "Summary".localized, icon: "chart.pie"),
        TabItem(id: 3, title: "Settings".localized, icon: "gearshape")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border with subtle shadow
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(spacing: 0) {
                ForEach(tabs, id: \.id) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab.id,
                        namespace: tabIndicator
                    ) {
                        selectTab(tab.id)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                // Match app's background color
                Rectangle()
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        Rectangle()
                            .fill(Color.primary.opacity(0.02))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
            )
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }
    
    private func selectTab(_ index: Int) {
        // Prevent redundant selections
        guard selectedTab != index else { return }
        
        withAnimation(.interpolatingSpring(
            stiffness: performanceManager.springStiffness,
            damping: performanceManager.springDamping
        )) {
            selectedTab = index
        }
        
        // Add a subtle bounce effect
        withAnimation(.easeInOut(duration: 0.1)) {
            bounceEffect = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                bounceEffect = false
            }
        }
        
        // Haptic feedback with slight delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hapticFeedback.impactOccurred()
        }
    }
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background indicator for selected state
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 64, height: 32)
                            .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                            .animation(.interpolatingSpring(
                                stiffness: PerformanceManager.shared.springStiffness,
                                damping: PerformanceManager.shared.springDamping
                            ), value: isSelected)
                    }
                    
                    // Icon with animation
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected ? 
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.primary.opacity(0.6), Color.primary.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isSelected ? 1.1 : (isPressed ? 0.95 : 1.0))
                        .animation(.interpolatingSpring(stiffness: 600, damping: 20), value: isSelected)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                        .offset(y: isPressed ? 1 : 0)
                }
                .frame(height: 32)
                
                // Title with smooth fade transition
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.6))
                    .scaleEffect(isSelected ? 1.0 : 0.95)
                    .opacity(isSelected ? 1.0 : 0.8)
                    .animation(.interpolatingSpring(stiffness: 400, damping: 25), value: isSelected)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        } perform: {}
    }
}

struct TabItem {
    let id: Int
    let title: String
    let icon: String
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab = 2
        @State private var incomes: [Income] = []
        @State private var expenses: [Expense] = []
        @State private var user: User? = User(isGuest: true)
        @State private var userId = "guest"
        @State private var showAuthSheet = false
        
        var body: some View {
            AnimatedTabView(
                selectedTab: $selectedTab,
                incomes: $incomes,
                expenses: $expenses,
                user: $user,
                userId: $userId,
                showAuthSheet: $showAuthSheet
            )
        }
    }
    
    return PreviewWrapper()
}