import SwiftUI
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import GoogleSignIn
import Combine
import CryptoKit

/// Authentication service for Dozzi app
/// Handles Firebase Authentication with Apple Sign In and Google Sign In
@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let (credential, nonce) = try await performAppleSignIn()
            let _ = try await authenticateWithFirebase(appleIDCredential: credential, nonce: nonce)
        } catch {
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private var currentAppleSignInDelegate: AppleSignInDelegate?
    
    private func performAppleSignIn() async throws -> (ASAuthorizationAppleIDCredential, String) {
        let nonce = randomNonceString()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // This ensures Apple shows privacy options to users
        if #available(iOS 13.0, *) {
            // Privacy options are automatically shown when requesting email
            // Users will see options for:
            // - "Hide My Email" (forwards to anonymous @privaterelay.appleid.com)
            // - "Share My Email" (uses real email)
            // - Name sharing options (share/don't share name)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Ensure UI operations happen on main queue
            DispatchQueue.main.async {
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                
                // Keep strong reference to prevent deallocation
                let delegate = AppleSignInDelegate(nonce: nonce) { result in
                    self.currentAppleSignInDelegate = nil // Clear reference
                    continuation.resume(with: result)
                }
                
                self.currentAppleSignInDelegate = delegate
                authorizationController.delegate = delegate
                authorizationController.presentationContextProvider = delegate
                authorizationController.performRequests()
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleConfigError
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let presentingViewController = await getRootViewController() else {
                throw AuthError.noPresentingViewController
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleTokenError
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let _ = try await Auth.auth().signIn(with: credential)
            
        } catch {
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out & Account Deletion
    
    func signOut() async {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    // For complete account deletion with Apple ID revocation
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let user = Auth.auth().currentUser else {
                throw AuthError.notAuthenticated
            }
            
            print("🗑️ Starting account deletion process...")
            print("   User UID: \(user.uid)")
            print("   Provider data: \(user.providerData)")
            
            // Check if this is an Apple Sign In user
            let isAppleUser = user.providerData.contains { $0.providerID == "apple.com" }
            
            if isAppleUser {
                print("🍎 Apple user detected - revoking Apple ID authorization...")
                
                // For Apple users, we need to get a fresh authorization code to revoke the token
                let (_, authCode) = try await performAppleReauthorization()
                
                // Revoke the Apple ID authorization
                if let authCodeString = String(data: authCode, encoding: .utf8) {
                    print("📝 Revoking Apple authorization with code...")
                    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                    print("✅ Apple authorization revoked successfully")
                } else {
                    print("❌ Failed to get authorization code string")
                }
            }
            
            // Delete the Firebase user account
            print("🔥 Deleting Firebase user...")
            try await user.delete()
            print("✅ Firebase user deleted successfully")
            print("🎉 Account deletion complete! You can now sign in fresh.")
            
        } catch {
            print("❌ Account deletion failed: \(error)")
            errorMessage = "Account deletion failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Quick deletion for testing (just deletes Firebase user)
    func deleteFirebaseUserOnly() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let user = Auth.auth().currentUser else {
                throw AuthError.notAuthenticated
            }
            
            print("🗑️ Deleting Firebase user only (for testing)...")
            print("   User UID: \(user.uid)")
            
            try await user.delete()
            print("✅ Firebase user deleted - you can now test fresh sign in")
            
        } catch {
            print("❌ Firebase user deletion failed: \(error)")
            errorMessage = "User deletion failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func performAppleReauthorization() async throws -> (ASAuthorizationAppleIDCredential, Data) {
        let nonce = randomNonceString()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                
                let delegate = AppleReauthorizationDelegate { result in
                    continuation.resume(with: result)
                }
                
                authorizationController.delegate = delegate
                authorizationController.presentationContextProvider = delegate
                authorizationController.performRequests()
            }
        }
    }
    
    // MARK: - Firebase Token
    
    func getUserToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        
        return try await user.getIDToken()
    }
    
    // MARK: - Helper Methods
    
    private func authenticateWithFirebase(appleIDCredential: ASAuthorizationAppleIDCredential, nonce: String) async throws -> AuthDataResult {
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.appleTokenError
        }
        
        // Use modern Firebase credential creation
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        let result = try await Auth.auth().signIn(with: credential)
        
        // IMPORTANT: User info is ONLY available on FIRST authorization
        // On subsequent sign-ins, these will be empty even if user shared them before
        print("📋 Apple Credential Info Check:")
        
        var isFirstTimeUser = false
        var displayName: String?
        
        if let email = appleIDCredential.email {
            print("✅ NEW USER - Email provided: \(email)")
            isFirstTimeUser = true
            // This could be:
            // - Real email: user@example.com  
            // - Private relay: xyz123@privaterelay.appleid.com
        } else {
            print("ℹ️ RETURNING USER - No email (normal for repeat sign-ins)")
        }
        
        if let fullName = appleIDCredential.fullName,
           let givenName = fullName.givenName,
           let familyName = fullName.familyName {
            displayName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            print("✅ NEW USER - Name provided: \(displayName!)")
            isFirstTimeUser = true
        } else {
            print("ℹ️ RETURNING USER - No name (normal for repeat sign-ins)")
        }
        
        print("🔍 User status: \(isFirstTimeUser ? "FIRST_TIME" : "RETURNING")")
        
        // CRITICAL: Update Firebase user profile with Apple-provided info on first sign-in
        // This ensures Firebase stores the display name permanently
        if isFirstTimeUser, let displayName = displayName {
            print("💾 FIRST TIME USER - Storing display name in Firebase...")
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            do {
                try await changeRequest.commitChanges()
                print("✅ Display name saved to Firebase: \(displayName)")
            } catch {
                print("⚠️ Failed to save display name: \(error.localizedDescription)")
            }
        }
        
        // Important: Check final Firebase user info
        // Firebase should now have the display name stored permanently
        let firebaseUser = result.user
        print("🔥 Final Firebase user info:")
        print("   UID: \(firebaseUser.uid)")
        print("   Email: \(firebaseUser.email ?? "Not available")")
        print("   Display name: \(firebaseUser.displayName ?? "Not available")")
        print("   Provider data: \(firebaseUser.providerData)")
        
        // Reload user to ensure we have the latest profile data
        try await firebaseUser.reload()
        print("🔄 After reload - Display name: \(firebaseUser.displayName ?? "Still not available")")
        
        return result
    }
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    // MARK: - Apple Sign In Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let nonce: String
    private let completion: (Result<(ASAuthorizationAppleIDCredential, String), Error>) -> Void
    
    init(nonce: String, completion: @escaping (Result<(ASAuthorizationAppleIDCredential, String), Error>) -> Void) {
        self.nonce = nonce
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            self.completion(.success((appleIDCredential, self.nonce)))
        } else {
            self.completion(.failure(AuthError.appleTokenError))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Apple Reauthorization Delegate (for account deletion)

class AppleReauthorizationDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<(ASAuthorizationAppleIDCredential, Data), Error>) -> Void
    
    init(completion: @escaping (Result<(ASAuthorizationAppleIDCredential, Data), Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let authCode = appleIDCredential.authorizationCode {
            self.completion(.success((appleIDCredential, authCode)))
        } else {
            self.completion(.failure(AuthError.appleTokenError))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case googleConfigError
    case noPresentingViewController
    case googleTokenError
    case appleTokenError
    case notAuthenticated
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .googleConfigError:
            return "Google Sign In configuration error"
        case .noPresentingViewController:
            return "No presenting view controller available"
        case .googleTokenError:
            return "Failed to get Google ID token"
        case .appleTokenError:
            return "Failed to get Apple ID token"
        case .notAuthenticated:
            return "User not authenticated"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}
