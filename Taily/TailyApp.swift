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
        // For production builds, choose your real provider:
        // If your app primarily targets iOS 14+ devices that support App Attest,
        // this is the strongest option for device attestation.
        if #available(iOS 14.0, *) {
            let providerFactory = AppAttestProviderFactory()
            AppCheck.setProviderFactory(providerFactory)
        } else {
            // For older iOS versions or if you prefer DeviceCheck for broader compatibility.
            // DeviceCheck provides a good level of protection.
            let providerFactory = DeviceCheckProviderFactory()
            AppCheck.setProviderFactory(providerFactory)
        }
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

