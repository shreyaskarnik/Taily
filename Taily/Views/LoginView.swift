import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // App Logo and Title
                VStack(spacing: 20) {
                    // Dozzi mascot animation could go here
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Dozzi")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Personalized bedtime stories for your little ones")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Sign In Options
                VStack(spacing: 20) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            // Configure the request if needed
                        },
                        onCompletion: { result in
                            Task {
                                await authService.signInWithApple()
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    // Google Sign In
                    Button(action: {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.title2)
                            
                            Text("Sign in with Google")
                                .font(.title3.weight(.medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.33, blue: 0.32), Color(red: 0.91, green: 0.51, blue: 0.40)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                    .disabled(authService.isLoading)
                    
                    // Guest Mode (Optional)
                    Button(action: {
                        // For now, just dismiss the login
                        dismiss()
                    }) {
                        Text("Continue as Guest")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                // Loading State
                if authService.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Signing in...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Error Message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Terms and Privacy
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption.weight(.medium))
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        .font(.caption.weight(.medium))
                    }
                }
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}