import SwiftUI

struct SubscriptionStatusView: View {
    let status: SubscriptionStatus
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: status.statusIcon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(status.displayText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Premium badge
            if status.isPremium {
                Text("PREMIUM")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        switch status {
        case .free(let remaining):
            return remaining > 0 ? .orange : .red
        case .unlimited:
            return .blue
        }
    }
    
    private var iconBackgroundColor: Color {
        switch status {
        case .free(let remaining):
            return remaining > 0 ? Color.orange.opacity(0.2) : Color.red.opacity(0.2)
        case .unlimited:
            return Color.blue.opacity(0.2)
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .free(let remaining):
            return remaining > 0 ? Color.orange.opacity(0.05) : Color.red.opacity(0.05)
        case .unlimited:
            return Color.blue.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        switch status {
        case .free(let remaining):
            return remaining > 0 ? Color.orange.opacity(0.3) : Color.red.opacity(0.3)
        case .unlimited:
            return Color.blue.opacity(0.3)
        }
    }
    
    private var subtitle: String {
        switch status {
        case .free(let remaining):
            if remaining > 0 {
                return "Enjoying premium voices! Upgrade for unlimited access"
            } else {
                return "Upgrade to continue with premium voices and unlimited stories"
            }
        case .unlimited:
            return "Create unlimited stories with premium Google Cloud voices"
        }
    }
}

// MARK: - Enhanced Status Views

struct SubscriptionStatusBanner: View {
    let status: SubscriptionStatus
    let onUpgradeTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SubscriptionStatusView(status: status)
            
            // Upgrade prompt for free users
            if case .free(let remaining) = status, remaining <= 1 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Running low on stories?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Upgrade to unlimited for just $2.99")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Upgrade") {
                        onUpgradeTap()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.05))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Free - 2 Stories") {
    VStack(spacing: 20) {
        SubscriptionStatusView(status: .free(storiesRemaining: 2))
        SubscriptionStatusView(status: .free(storiesRemaining: 1))
        SubscriptionStatusView(status: .free(storiesRemaining: 0))
        SubscriptionStatusView(status: .unlimited)
    }
    .padding()
}

#Preview("Status Banner") {
    SubscriptionStatusBanner(status: .free(storiesRemaining: 1)) {
        print("Upgrade tapped")
    }
    .padding()
}