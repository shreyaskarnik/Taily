//
//  ContentView.swift
//  Dozzi
//
//  Created by Shreyas Karnik on 7/6/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    // Simplified: No need for size classes or sidebar state anymore
    
    var body: some View {
        // Use the same TabView layout for both iPhone and iPad
        iPhoneLayout
    }
    
    private var iPhoneLayout: some View {
        TabView {
            ChatStyleStoryInputView()
                .tabItem {
                    Label("Create Story", systemImage: "book.fill")
                }
            
            ChildProfilesTabView()
                .tabItem {
                    Label("Child Profiles", systemImage: "person.2.fill")
                }
            
            StoryLibraryView()
                .tabItem {
                    Label("Story Library", systemImage: "books.vertical.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Liquid Glass tab bar styling for iOS 26+
            let appearance = UITabBarAppearance()
            
            // Use translucent material background
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            
            // Enhanced glass effect with subtle materials
            appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            appearance.shadowImage = UIImage()
            
            // Modern icon styling
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ChildProfilesTabView: View {
    @StateObject private var profileManager = ChildProfileManager()
    
    var body: some View {
        ChildProfileView(profileManager: profileManager)
    }
}


struct StoryLibraryView: View {
    @StateObject private var libraryManager = StoryLibraryManager()
    @StateObject private var storyGenerator = StoryGenerator()
    @State private var showingStoryView = false
    @State private var selectedSavedStory: SavedStory?
    
    var body: some View {
        NavigationStack {
            Group {
                if libraryManager.isEmpty {
                    emptyLibraryView
                } else {
                    libraryContentView
                }
            }
            .navigationTitle("Story Library")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingStoryView) {
                if let savedStory = selectedSavedStory {
                    StoryView(
                        storyGenerator: storyGenerator,
                        parameters: savedStory.parameters
                    )
                    .onAppear {
                        // Load the saved story into the generator
                        loadSavedStory(savedStory)
                    }
                }
            }
        }
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: 30) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("Story Library")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Your saved stories will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Create your first story to get started!")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var libraryContentView: some View {
        List {
            ForEach(libraryManager.savedStories) { savedStory in
                StoryLibraryRow(savedStory: savedStory) {
                    selectedSavedStory = savedStory
                    showingStoryView = true
                }
            }
            .onDelete(perform: libraryManager.deleteStory)
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadSavedStory(_ savedStory: SavedStory) {
        // Clear any existing generated story and set the saved story
        storyGenerator.generatedStory = nil
        storyGenerator.savedStory = savedStory.story
    }
}

struct StoryLibraryRow: View {
    let savedStory: SavedStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Story emoji and title
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(savedStory.story.emoji)
                            .font(.title2)
                        Text(savedStory.story.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Story metadata
                    HStack {
                        Text("For \(savedStory.parameters.childName)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(savedStory.dateModified, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Story themes preview
                    HStack {
                        ForEach(savedStory.parameters.themes.prefix(3), id: \.self) { theme in
                            Text(theme.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if savedStory.parameters.themes.count > 3 {
                            Text("+\(savedStory.parameters.themes.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Speech Settings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speech Rate")
                        Slider(value: $speechSynthesizer.speechRate, in: 0.1...1.0, step: 0.1) {
                            Text("Speech Rate")
                        } minimumValueLabel: {
                            Text("Slow")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("Fast")
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink(destination: VoiceSelectionView(speechSynthesizer: speechSynthesizer)) {
                        HStack {
                            Text("Voice")
                            Spacer()
                            Text(speechSynthesizer.selectedVoice?.name ?? "Default")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Story Preferences")) {
                    HStack {
                        Text("Default Story Length")
                        Spacer()
                        Text("Medium")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Preferred Tone")
                        Spacer()
                        Text("Calming")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct VoiceSelectionView: View {
    @ObservedObject var speechSynthesizer: SpeechSynthesizer
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("Available Voices")) {
                ForEach(speechSynthesizer.availableVoices, id: \.identifier) { voice in
                    VoiceRow(
                        voice: voice,
                        isSelected: speechSynthesizer.selectedVoice?.identifier == voice.identifier,
                        speechSynthesizer: speechSynthesizer
                    ) {
                        speechSynthesizer.setVoice(voice)
                    }
                }
            }
        }
        .navigationTitle("Select Voice")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            speechSynthesizer.stopSpeaking()
        }
    }
}

struct VoiceRow: View {
    let voice: AVSpeechSynthesisVoice
    let isSelected: Bool
    let speechSynthesizer: SpeechSynthesizer
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.name)
                    .font(.headline)
                
                HStack {
                    Text(voice.language)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if voice.quality == .enhanced {
                        Text("Enhanced")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                speechSynthesizer.sampleVoice(voice)
            }) {
                Image(systemName: speechSynthesizer.isSpeaking ? "stop.fill" : "play.fill")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    ContentView()
}
