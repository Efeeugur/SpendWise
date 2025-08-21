import SwiftUI

struct RecommendationsView: View {
    @StateObject private var recommendationManager = RecommendationManager.shared
    @Binding var incomes: [Income]
    @Binding var expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if recommendationManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing recommendations...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recommendationManager.recommendations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("You are doing great!")
                            .font(.title2.bold())
                        
                        Text("Currently, we have no recommendations. Your financial situation looks good.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(recommendationManager.recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Smart Recommendations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        recommendationManager.generateRecommendations(incomes: incomes, expenses: expenses)
                    }
                }
            }
            .onAppear {
                recommendationManager.generateRecommendations(incomes: incomes, expenses: expenses)
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(recommendation.type.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Öncelik göstergesi
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Circle()
                            .fill(index <= recommendation.priority ? Color(recommendation.type.color) : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)
            
            if recommendation.actionable, let actionTitle = recommendation.actionTitle {
                Button(action: {
                    recommendation.action?()
                }) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(recommendation.type.color))
                        .cornerRadius(8)
                }
            }
            
            if recommendation.description.count > 100 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.black).opacity(0.05), radius: 5, x: 0, y: 2)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

struct RecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationsView(incomes: .constant([]), expenses: .constant([]))
    }
} 