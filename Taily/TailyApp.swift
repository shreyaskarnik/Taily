//
//  DozziApp.swift
//  Dozzi
//
//  Created by Shreyas Karnik on 7/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseFirestore
import FirebaseFunctions

@main
struct DozziApp: App {

    init() {
        // --- App Check Configuration (BEFORE FirebaseApp.configure()) ---

        // IMPORTANT: For development and testing on simulators or unregistered physical devices,
        // use the AppCheckDebugProviderFactory.
        // You MUST copy the debug token printed in your console and register it
        // in the Firebase console under "App Check" for your iOS app.
        // Remove or conditionally compile this for your production builds!
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #else
        // For production builds, use DeviceCheck provider for broader compatibility
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif

        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        
        // Configure Functions for development
        #if DEBUG
        // Uncomment for local development with emulator
        // Functions.functions().useEmulator(withHost: "localhost", port: 5001)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

