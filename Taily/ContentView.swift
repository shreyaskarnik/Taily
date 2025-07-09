//
//  ContentView.swift
//  Taily
//
//  Created by Shreyas Karnik on 7/6/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                // iPad layout
                iPadLayout
            } else {
                // iPhone layout
                iPhoneLayout
            }
        }
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
    }
    
    private var iPadLayout: some View {
        NavigationView {
            Sidebar()
            
            // Default detail view
            WelcomeView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct Sidebar: View {
    var body: some View {
        List {
            NavigationLink(destination: ChatStyleStoryInputView()) {
                Label("Create Story", systemImage: "book.fill")
            }
            
            NavigationLink(destination: ChildProfilesTabView()) {
                Label("Child Profiles", systemImage: "person.2.fill")
            }
            
            NavigationLink(destination: StoryLibraryView()) {
                Label("Story Library", systemImage: "books.vertical.fill")
            }
            
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
        }
        .navigationTitle("Taily")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ChildProfilesTabView: View {
    @StateObject private var profileManager = ChildProfileManager()
    
    var body: some View {
        ChildProfileView(profileManager: profileManager)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to Taily")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Create magical bedtime stories for your little ones")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "sparkles",
                    title: "AI-Powered Stories",
                    description: "Personalized stories generated just for your child"
                )
                
                FeatureRow(
                    icon: "speaker.wave.2.fill",
                    title: "Read Aloud",
                    description: "High-quality text-to-speech narration"
                )
                
                FeatureRow(
                    icon: "heart.fill",
                    title: "Values-Based",
                    description: "Stories that teach kindness, bravery, and more"
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct StoryLibraryView: View {
    @StateObject private var libraryManager = StoryLibraryManager()
    @State private var showingStoryView = false
    @State private var selectedSavedStory: SavedStory?
    
    var body: some View {
        NavigationView {
            Group {
                if libraryManager.isEmpty {
                    emptyLibraryView
                } else {
                    libraryContentView
                }
            }
            .navigationTitle("Story Library")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingStoryView) {
                if let savedStory = selectedSavedStory {
                    SavedStoryView(
                        savedStory: savedStory,
                        libraryManager: libraryManager
                    )
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
