import SwiftUI

struct PaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with Dozzi character
                    PaywallHeaderView()
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Benefits section
                    PaywallBenefitsView()
                    
                    // Pricing section
                    PaywallPricingView(subscriptionManager: subscriptionManager)
                    
                    // Trust indicators
                    PaywallTrustView()
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Unlock Unlimited Stories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PaywallHeaderView: View {
    @State private var glowAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Liquid Glass Dozzi character container
            ZStack {
                // Outer glass layer with dynamic glow
                Circle()
                    .fill(.ultraThinMaterial, style: FillStyle())
                    .frame(width: 140, height: 140)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.6),
                                        Color.purple.opacity(0.4),
                                        Color.cyan.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 20)
                            .scaleEffect(glowAnimation ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: glowAnimation)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 8)
                
                // Inner glass character container
                Circle()
                    .fill(.regularMaterial, style: FillStyle())
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.clear,
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Dozzi character animation
                LottieDozziView(
                    currentAnimation: .constant(.magic),
                    mood: .constant(.happy)
                )
                .frame(width: 80, height: 80)
                .scaleEffect(glowAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowAnimation)
            }
            .onAppear {
                glowAnimation = true
            }
            
            VStack(spacing: 12) {
                Text("Hi! I'm Dozzi!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("You've been enjoying premium Google Cloud voices! Upgrade now to keep the magic going with unlimited stories")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

struct PaywallBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What you'll get:")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                PaywallBenefitRow(
                    icon: "infinity",
                    title: "Unlimited Stories",
                    description: "Create as many personalized stories as you want",
                    color: .blue
                )
                
                PaywallBenefitRow(
                    icon: "speaker.wave.3.fill",
                    title: "Premium Voices",
                    description: "5 high-quality, age-appropriate Google Cloud voices",
                    color: .purple
                )
                
                PaywallBenefitRow(
                    icon: "heart.fill",
                    title: "Always Personalized",
                    description: "Every story features your child as the hero",
                    color: .pink
                )
                
                PaywallBenefitRow(
                    icon: "shield.fill",
                    title: "Safe & Private",
                    description: "Stories generated on-device, no data shared",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }
}

struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct PaywallPricingView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Price comparison
            VStack(spacing: 12) {
                Text("One-time purchase")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let product = subscriptionManager.store.unlimitedStoriesProduct {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(product.formattedPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("once")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("$2.99")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Text("Less than a single bedtime book!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Purchase button
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await subscriptionManager.purchaseUnlimitedStories()
                    }
                }) {
                    HStack {
                        if subscriptionManager.isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        VStack(spacing: 2) {
                            Text(subscriptionManager.isPurchasing ? "Processing..." : "Unlock Unlimited Stories")
                                .fontWeight(.semibold)
                            
                            Text("One-time purchase • No subscription")
                                .font(.caption)
                                .opacity(0.9)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(subscriptionManager.isPurchasing)
                .opacity(subscriptionManager.isPurchasing ? 0.8 : 1.0)
                .scaleEffect(subscriptionManager.isPurchasing ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: subscriptionManager.isPurchasing)
                
                // Restore purchases
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
                .foregroundColor(.secondary)
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
}

struct PaywallTrustView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                TrustBadge(icon: "lock.shield", text: "Secure")
                TrustBadge(icon: "heart", text: "Kid-Safe")
                TrustBadge(icon: "checkmark.seal", text: "No Ads")
            }
            
            VStack(spacing: 4) {
                Text("✨ Join thousands of happy families")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("No subscriptions • No recurring charges • Cancel anytime")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error Display

extension PaywallView {
    private var errorAlert: some View {
        Group {
            if let error = subscriptionManager.purchaseError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
    }
}

#Preview {
    PaywallView(subscriptionManager: SubscriptionManager())
}
