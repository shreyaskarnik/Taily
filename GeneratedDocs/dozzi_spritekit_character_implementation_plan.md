# Dozzi SpriteKit Character Implementation Plan

## Overview

This document outlines the complete implementation plan for adding Dozzi, a goofy and lovable animated character, to the bedtime story app using SpriteKit integrated with SwiftUI. Dozzi will serve as the app's mascot, guide users through the experience, and add personality to key interactions.

## Character Design Concept

### **Dozzi's Personality**

**Core Traits:**
- Friendly night owl with a whimsical, slightly sleepy personality
- Wears cozy pajamas with star patterns and a floppy nightcap
- Large, expressive eyes that convey emotion
- Gentle, bouncy movements that feel magical but calming
- Acts as a bedtime companion and story guide

**Visual Design:**
- **Base**: Soft, round owl-like character in pastel blues and purples
- **Clothing**: Star-patterned pajamas, oversized nightcap with a bell
- **Eyes**: Large, animated eyes with long eyelashes
- **Accessories**: Magic wand with star tip, small pillow or blanket
- **Size**: Designed to work well at 120x120 to 200x200 points

**Character Voice (Visual):**
- Communicates through animations, expressions, and particle effects
- Uses thought bubbles with simple icons for complex concepts
- Reacts to user interactions with appropriate emotions

## Animation States & Behaviors

### **Primary Animation States**

```swift
enum DozziAnimation {
    case idle
    case excited
    case thinking
    case magic
    case sleepy
    case celebrate
    case sad
    case waving
    case reading
    case listening
}

enum DozziMood {
    case neutral
    case happy
    case excited
    case sleepy
    case magical
    case confused
}
```

### **Detailed Animation Specifications**

#### **1. Idle Animation (Default State)**
- **Duration**: 3-4 seconds loop
- **Behavior**: 
  - Gentle floating up/down (2-3 points)
  - Slow breathing motion (scale 0.98-1.02)
  - Occasional eye blinks (every 2-3 seconds)
  - Nightcap sways slightly with floating motion
- **Particle Effects**: Occasional sparkle near wand tip
- **Trigger**: Default state when no other animation is active

#### **2. Excited Animation**
- **Duration**: 2-3 seconds
- **Behavior**:
  - Bouncing motion (10-15 points high)
  - Eyes grow larger with joy
  - Wand waves back and forth
  - Nightcap bounces energetically
- **Particle Effects**: Burst of colorful stars around character
- **Trigger**: Story creation started, successful purchase, app launch
- **Sound**: Light magical chime (if sound enabled)

#### **3. Thinking Animation**
- **Duration**: 1-2 seconds loop
- **Behavior**:
  - Tilts head side to side
  - Eyes look up and around
  - Taps wand against chin/head
  - Small thought bubble appears with rotating dots
- **Particle Effects**: Small question mark particles
- **Trigger**: Story generation in progress, loading states
- **Transition**: Smoothly transitions to magic animation

#### **4. Magic Animation (Story Generation)**
- **Duration**: 3-4 seconds
- **Behavior**:
  - Dramatic wand wave in figure-8 pattern
  - Eyes glow with magical light
  - Character spins 360° slowly
  - Nightcap floats as if weightless
- **Particle Effects**: 
  - Rainbow sparkles following wand movement
  - Magical dust swirling around character
  - Small stars materializing and floating away
- **Trigger**: During story generation using Foundation Models
- **Sound**: Soft magical whoosh

#### **5. Sleepy Animation**
- **Duration**: 4-5 seconds loop
- **Behavior**:
  - Slow, heavy blinking
  - Head nods forward sleepily
  - Yawning motion with eyes closed
  - Slower floating motion
  - Nightcap droops over one eye
- **Particle Effects**: "Z" sleep particles floating up
- **Trigger**: Evening hours (8PM-6AM), story completion, bedtime mode
- **Sound**: Soft yawn sound

#### **6. Celebration Animation**
- **Duration**: 3-4 seconds
- **Behavior**:
  - Energetic jumping with arms raised
  - Eyes sparkle with joy
  - Wand creates figure-8 patterns in air
  - Spins around with arms outstretched
- **Particle Effects**: 
  - Confetti explosion
  - Firework-style star bursts
  - Rainbow trail following wand
- **Trigger**: Premium purchase completed, milestone achievements
- **Sound**: Happy celebration chime

#### **7. Sad Animation**
- **Duration**: 2-3 seconds
- **Behavior**:
  - Head droops down
  - Eyes become smaller and downcast
  - Slow, dejected floating motion
  - Wand points downward
- **Particle Effects**: Small rain clouds above head
- **Trigger**: Purchase cancelled, errors, no stories remaining
- **Recovery**: Automatically transitions back to idle after duration

#### **8. Waving Animation**
- **Duration**: 2 seconds
- **Behavior**:
  - Enthusiastic arm waving
  - Happy facial expression
  - Slight bouncing motion
  - Nightcap bobs with movement
- **Particle Effects**: Heart-shaped sparkles
- **Trigger**: App launch greeting, successful story save
- **Sound**: Friendly greeting chime

#### **9. Reading Animation**
- **Duration**: 4-6 seconds loop
- **Behavior**:
  - Holds miniature book in front
  - Eyes move left to right as if reading
  - Occasional page turning gesture
  - Gentle nodding as if enjoying story
- **Particle Effects**: Soft book pages floating around
- **Trigger**: During story playback/TTS
- **Accessories**: Tiny reading glasses appear

#### **10. Listening Animation**
- **Duration**: 3-4 seconds loop
- **Behavior**:
  - Ear (if visible) perks up
  - Head tilts toward sound source
  - Eyes wide with attention
  - Hand cupped near ear
- **Particle Effects**: Sound wave visualizations
- **Trigger**: During audio playback, voice input
- **Interaction**: Responds to audio levels with head movement

## Technical Implementation

### **Core SpriteKit Architecture**

```swift
import SpriteKit
import SwiftUI

class DozziCharacterScene: SKScene {
    
    // MARK: - Properties
    private var dozzi: SKSpriteNode!
    private var wand: SKSpriteNode!
    private var nightcap: SKSpriteNode!
    private var eyes: SKSpriteNode!
    private var thoughtBubble: SKSpriteNode?
    
    private var currentAnimation: DozziAnimation = .idle
    private var currentMood: DozziMood = .neutral
    private var isAnimating = false
    
    private var idleTimer: Timer?
    private var blinkTimer: Timer?
    
    // Animation actions
    private var breathingAction: SKAction!
    private var floatingAction: SKAction!
    private var blinkAction: SKAction!
    
    // Particle systems
    private var sparkleEmitter: SKEmitterNode!
    private var magicEmitter: SKEmitterNode!
    private var celebrationEmitter: SKEmitterNode!
    
    // MARK: - Scene Setup
    override func didMoveToView(_ view: SKView) {
        setupScene()
        setupDozziCharacter()
        setupParticleSystems()
        setupAnimations()
        startIdleAnimation()
        startBlinkTimer()
    }
    
    override func willMoveFromView(view: SKView) {
        cleanup()
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    private func setupDozziCharacter() {
        // Main character body
        dozzi = SKSpriteNode(imageNamed: "dozzi_body")
        dozzi.size = CGSize(width: 80, height: 80)
        dozzi.position = CGPoint.zero
        dozzi.zPosition = 10
        addChild(dozzi)
        
        // Wand accessory
        wand = SKSpriteNode(imageNamed: "dozzi_wand")
        wand.size = CGSize(width: 25, height: 40)
        wand.position = CGPoint(x: 30, y: 10)
        wand.zPosition = 11
        dozzi.addChild(wand)
        
        // Nightcap
        nightcap = SKSpriteNode(imageNamed: "dozzi_nightcap")
        nightcap.size = CGSize(width: 50, height: 60)
        nightcap.position = CGPoint(x: 0, y: 25)
        nightcap.zPosition = 12
        dozzi.addChild(nightcap)
        
        // Eyes (separate for animation)
        eyes = SKSpriteNode(imageNamed: "dozzi_eyes_open")
        eyes.size = CGSize(width: 30, height: 15)
        eyes.position = CGPoint(x: 0, y: 5)
        eyes.zPosition = 13
        dozzi.addChild(eyes)
    }
    
    private func setupParticleSystems() {
        // Sparkle particles for idle/magic
        sparkleEmitter = SKEmitterNode(fileNamed: "DozziSparkles")
        sparkleEmitter?.position = CGPoint(x: 30, y: 20)
        sparkleEmitter?.zPosition = 5
        sparkleEmitter?.particleBirthRate = 2
        dozzi.addChild(sparkleEmitter!)
        
        // Magic particles for story generation
        magicEmitter = SKEmitterNode(fileNamed: "DozziMagic")
        magicEmitter?.position = CGPoint.zero
        magicEmitter?.zPosition = 5
        magicEmitter?.particleBirthRate = 0
        addChild(magicEmitter!)
        
        // Celebration particles
        celebrationEmitter = SKEmitterNode(fileNamed: "DozziCelebration")
        celebrationEmitter?.position = CGPoint.zero
        celebrationEmitter?.zPosition = 5
        celebrationEmitter?.particleBirthRate = 0
        addChild(celebrationEmitter!)
    }
    
    private func setupAnimations() {
        // Breathing animation
        let breatheIn = SKAction.scale(to: 1.02, duration: 1.5)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scale(to: 0.98, duration: 1.5)
        breatheOut.timingMode = .easeInEaseOut
        breathingAction = SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut]))
        
        // Floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 3, duration: 2.0)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -3, duration: 2.0)
        floatDown.timingMode = .easeInEaseOut
        floatingAction = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
        
        // Blink animation
        let closeBlink = SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_closed"))
        let openBlink = SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_open"))
        let blinkSequence = SKAction.sequence([
            closeBlink,
            SKAction.wait(forDuration: 0.1),
            openBlink
        ])
        blinkAction = blinkSequence
    }
    
    // MARK: - Animation Control
    func playAnimation(_ animation: DozziAnimation, completion: (() -> Void)? = nil) {
        guard currentAnimation != animation || !isAnimating else { return }
        
        stopCurrentAnimation()
        currentAnimation = animation
        isAnimating = true
        
        switch animation {
        case .idle:
            performIdleAnimation()
        case .excited:
            performExcitedAnimation(completion: completion)
        case .thinking:
            performThinkingAnimation(completion: completion)
        case .magic:
            performMagicAnimation(completion: completion)
        case .sleepy:
            performSleepyAnimation(completion: completion)
        case .celebrate:
            performCelebrationAnimation(completion: completion)
        case .sad:
            performSadAnimation(completion: completion)
        case .waving:
            performWavingAnimation(completion: completion)
        case .reading:
            performReadingAnimation(completion: completion)
        case .listening:
            performListeningAnimation(completion: completion)
        }
    }
    
    private func stopCurrentAnimation() {
        dozzi.removeAllActions()
        wand.removeAllActions()
        nightcap.removeAllActions()
        eyes.removeAllActions()
        
        // Stop particle effects
        sparkleEmitter?.particleBirthRate = 2 // Keep minimal sparkles
        magicEmitter?.particleBirthRate = 0
        celebrationEmitter?.particleBirthRate = 0
        
        isAnimating = false
    }
    
    // MARK: - Specific Animation Implementations
    private func performIdleAnimation() {
        dozzi.run(breathingAction)
        dozzi.run(floatingAction)
        sparkleEmitter?.particleBirthRate = 2
        isAnimating = false // Idle is not considered "actively animating"
    }
    
    private func performExcitedAnimation(completion: (() -> Void)?) {
        // Bouncing motion
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.3),
            SKAction.moveBy(x: 0, y: -15, duration: 0.3)
        ])
        let repeatBounce = SKAction.repeat(bounce, count: 3)
        
        // Eye excitement
        let eyeGrow = SKAction.scale(to: 1.3, duration: 0.2)
        let eyeShrink = SKAction.scale(to: 1.0, duration: 0.2)
        let eyeExcitement = SKAction.sequence([eyeGrow, eyeShrink])
        
        // Wand wave
        let wandWave = SKAction.sequence([
            SKAction.rotate(byAngle: .pi/4, duration: 0.3),
            SKAction.rotate(byAngle: -.pi/2, duration: 0.6),
            SKAction.rotate(byAngle: .pi/4, duration: 0.3)
        ])
        
        // Particle burst
        sparkleEmitter?.particleBirthRate = 20
        
        let group = SKAction.group([repeatBounce])
        let sequence = SKAction.sequence([
            group,
            SKAction.run { [weak self] in
                self?.sparkleEmitter?.particleBirthRate = 2
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(sequence)
        eyes.run(SKAction.repeat(eyeExcitement, count: 3))
        wand.run(wandWave)
    }
    
    private func performThinkingAnimation(completion: (() -> Void)?) {
        // Head tilt
        let tiltLeft = SKAction.rotate(toAngle: -.pi/8, duration: 0.5)
        let tiltRight = SKAction.rotate(toAngle: .pi/8, duration: 1.0)
        let tiltCenter = SKAction.rotate(toAngle: 0, duration: 0.5)
        let headTilt = SKAction.sequence([tiltLeft, tiltRight, tiltCenter])
        
        // Wand tap
        let wandTap = SKAction.sequence([
            SKAction.move(to: CGPoint(x: -10, y: 15), duration: 0.3),
            SKAction.wait(forDuration: 0.1),
            SKAction.move(to: CGPoint(x: 30, y: 10), duration: 0.3)
        ])
        
        // Thought bubble
        showThoughtBubble()
        
        let thinkingSequence = SKAction.sequence([
            headTilt,
            SKAction.run { [weak self] in
                self?.hideThoughtBubble()
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(thinkingSequence)
        wand.run(wandTap)
    }
    
    private func performMagicAnimation(completion: (() -> Void)?) {
        // Dramatic wand movement
        let wandPath = UIBezierPath()
        wandPath.move(to: CGPoint(x: 30, y: 10))
        wandPath.addCurve(to: CGPoint(x: -20, y: 30),
                         controlPoint1: CGPoint(x: 50, y: 40),
                         controlPoint2: CGPoint(x: 10, y: 50))
        wandPath.addCurve(to: CGPoint(x: 30, y: 10),
                         controlPoint1: CGPoint(x: -50, y: 10),
                         controlPoint2: CGPoint(x: 0, y: -10))
        
        let wandMagic = SKAction.follow(wandPath.cgPath, duration: 3.0)
        
        // Character spin
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        
        // Eye glow effect
        let eyeGlow = SKAction.sequence([
            SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_glow")),
            SKAction.wait(forDuration: 2.5),
            SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_open"))
        ])
        
        // Intense particle effects
        magicEmitter?.particleBirthRate = 50
        sparkleEmitter?.particleBirthRate = 30
        
        let magicSequence = SKAction.sequence([
            SKAction.group([spin]),
            SKAction.run { [weak self] in
                self?.magicEmitter?.particleBirthRate = 0
                self?.sparkleEmitter?.particleBirthRate = 2
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(magicSequence)
        wand.run(wandMagic)
        eyes.run(eyeGlow)
    }
    
    private func performSleepyAnimation(completion: (() -> Void)?) {
        // Slow, heavy movements
        let slowFloat = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1, duration: 3.0),
            SKAction.moveBy(x: 0, y: -1, duration: 3.0)
        ])
        
        // Droopy nightcap
        let capDroop = SKAction.rotate(toAngle: .pi/6, duration: 1.0)
        
        // Sleepy blink sequence
        let sleepyBlink = SKAction.sequence([
            SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_sleepy")),
            SKAction.wait(forDuration: 0.5),
            SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_closed")),
            SKAction.wait(forDuration: 1.0),
            SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_sleepy"))
        ])
        
        // Sleep particles
        addSleepParticles()
        
        dozzi.run(SKAction.repeatForever(slowFloat))
        nightcap.run(capDroop)
        eyes.run(SKAction.repeatForever(sleepyBlink))
        
        // This animation continues until manually stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            completion?()
        }
    }
    
    private func performCelebrationAnimation(completion: (() -> Void)?) {
        // Energetic jumping
        let bigJump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 25, duration: 0.4),
            SKAction.moveBy(x: 0, y: -25, duration: 0.4)
        ])
        let jumpSequence = SKAction.repeat(bigJump, count: 3)
        
        // Arms raised (simulate with scale)
        let celebrate = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let celebrateRepeat = SKAction.repeat(celebrate, count: 4)
        
        // Massive particle celebration
        celebrationEmitter?.particleBirthRate = 100
        sparkleEmitter?.particleBirthRate = 50
        
        let celebrationSequence = SKAction.sequence([
            SKAction.group([jumpSequence, celebrateRepeat]),
            SKAction.run { [weak self] in
                self?.celebrationEmitter?.particleBirthRate = 0
                self?.sparkleEmitter?.particleBirthRate = 2
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(celebrationSequence)
    }
    
    private func performSadAnimation(completion: (() -> Void)?) {
        // Droopy posture
        let droop = SKAction.scale(to: 0.9, duration: 1.0)
        let headDown = SKAction.rotate(toAngle: .pi/12, duration: 1.0)
        
        // Sad eyes
        let sadEyes = SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_sad"))
        
        // Wand points down
        let wandDown = SKAction.rotate(toAngle: .pi, duration: 1.0)
        
        // Rain cloud effect
        addRainCloud()
        
        let sadSequence = SKAction.sequence([
            SKAction.group([droop, headDown]),
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.removeRainCloud()
                // Reset to normal
                self?.dozzi.run(SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.5),
                    SKAction.rotate(toAngle: 0, duration: 0.5)
                ]))
                self?.wand.run(SKAction.rotate(toAngle: 0, duration: 0.5))
                self?.eyes.setTexture(SKTexture(imageNamed: "dozzi_eyes_open"))
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(sadSequence)
        eyes.run(sadEyes)
        wand.run(wandDown)
    }
    
    private func performWavingAnimation(completion: (() -> Void)?) {
        // Enthusiastic wave
        let wave = SKAction.sequence([
            SKAction.rotate(byAngle: .pi/3, duration: 0.2),
            SKAction.rotate(byAngle: -.pi/3, duration: 0.4),
            SKAction.rotate(byAngle: .pi/3, duration: 0.4),
            SKAction.rotate(byAngle: 0, duration: 0.2)
        ])
        let waveSequence = SKAction.repeat(wave, count: 2)
        
        // Happy bounce
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.3),
            SKAction.moveBy(x: 0, y: -8, duration: 0.3)
        ])
        let bounceSequence = SKAction.repeat(bounce, count: 3)
        
        // Heart particles
        sparkleEmitter?.particleBirthRate = 15
        
        let waveGroupSequence = SKAction.sequence([
            SKAction.group([bounceSequence]),
            SKAction.run { [weak self] in
                self?.sparkleEmitter?.particleBirthRate = 2
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(waveGroupSequence)
        wand.run(waveSequence)
    }
    
    private func performReadingAnimation(completion: (() -> Void)?) {
        // Add tiny book
        let book = SKSpriteNode(imageNamed: "tiny_book")
        book.size = CGSize(width: 15, height: 10)
        book.position = CGPoint(x: -15, y: 5)
        book.zPosition = 14
        dozzi.addChild(book)
        
        // Reading glasses
        let glasses = SKSpriteNode(imageNamed: "reading_glasses")
        glasses.size = CGSize(width: 25, height: 8)
        glasses.position = CGPoint(x: 0, y: 8)
        glasses.zPosition = 15
        dozzi.addChild(glasses)
        
        // Eye movement (reading)
        let lookLeft = SKAction.move(to: CGPoint(x: -3, y: 5), duration: 0.5)
        let lookRight = SKAction.move(to: CGPoint(x: 3, y: 5), duration: 1.0)
        let lookCenter = SKAction.move(to: CGPoint(x: 0, y: 5), duration: 0.5)
        let readingEyes = SKAction.sequence([lookLeft, lookRight, lookCenter])
        let readingLoop = SKAction.repeatForever(readingEyes)
        
        // Gentle nod
        let nod = SKAction.sequence([
            SKAction.rotate(byAngle: .pi/20, duration: 0.8),
            SKAction.rotate(byAngle: -.pi/20, duration: 0.8)
        ])
        let nodLoop = SKAction.repeatForever(nod)
        
        eyes.run(readingLoop)
        dozzi.run(nodLoop)
        
        // Continue until manually stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            book.removeFromParent()
            glasses.removeFromParent()
            completion?()
        }
    }
    
    private func performListeningAnimation(completion: (() -> Void)?) {
        // Head tilt toward sound
        let tilt = SKAction.rotate(toAngle: .pi/12, duration: 0.5)
        
        // Attentive eyes
        let attentiveEyes = SKAction.setTexture(SKTexture(imageNamed: "dozzi_eyes_wide"))
        
        // Sound wave visualization
        addSoundWaves()
        
        let listeningSequence = SKAction.sequence([
            tilt,
            SKAction.wait(forDuration: 3.0),
            SKAction.run { [weak self] in
                self?.removeSoundWaves()
                self?.dozzi.run(SKAction.rotate(toAngle: 0, duration: 0.5))
                self?.eyes.setTexture(SKTexture(imageNamed: "dozzi_eyes_open"))
                self?.performIdleAnimation()
                completion?()
            }
        ])
        
        dozzi.run(listeningSequence)
        eyes.run(attentiveEyes)
    }
    
    // MARK: - Helper Methods
    private func startBlinkTimer() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard self?.currentAnimation == .idle else { return }
            self?.eyes.run(self?.blinkAction ?? SKAction())
        }
    }
    
    private func showThoughtBubble() {
        thoughtBubble = SKSpriteNode(imageNamed: "thought_bubble")
        thoughtBubble?.size = CGSize(width: 30, height: 25)
        thoughtBubble?.position = CGPoint(x: 25, y: 40)
        thoughtBubble?.zPosition = 16
        dozzi.addChild(thoughtBubble!)
        
        // Animated dots in bubble
        let dots = SKSpriteNode(imageNamed: "thinking_dots")
        dots.size = CGSize(width: 15, height: 5)
        dots.position = CGPoint.zero
        thoughtBubble?.addChild(dots)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        dots.run(SKAction.repeatForever(pulse))
    }
    
    private func hideThoughtBubble() {
        thoughtBubble?.removeFromParent()
        thoughtBubble = nil
    }
    
    private func addSleepParticles() {
        let sleepEmitter = SKEmitterNode(fileNamed: "SleepParticles")
        sleepEmitter?.position = CGPoint(x: 0, y: 30)
        sleepEmitter?.zPosition = 5
        addChild(sleepEmitter!)
    }
    
    private func addRainCloud() {
        let cloud = SKSpriteNode(imageNamed: "rain_cloud")
        cloud.size = CGSize(width: 40, height: 20)
        cloud.position = CGPoint(x: 0, y: 50)
        cloud.zPosition = 8
        addChild(cloud)
        
        let rainEmitter = SKEmitterNode(fileNamed: "RainParticles")
        rainEmitter?.position = CGPoint(x: 0, y: -10)
        cloud.addChild(rainEmitter!)
    }
    
    private func removeRainCloud() {
        children.filter { $0.name == "rain_cloud" }.forEach { $0.removeFromParent() }
    }
    
    private func addSoundWaves() {
        for i in 0..<3 {
            let wave = SKShapeNode(circleOfRadius: CGFloat(10 + i * 5))
            wave.strokeColor = .blue
            wave.fillColor = .clear
            wave.alpha = 0.3
            wave.position = CGPoint(x: -30, y: 10)
            wave.zPosition = 6
            addChild(wave)
            
            let expand = SKAction.scale(to: 2.0, duration: 1.0)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.3),
                SKAction.group([expand, fade]),
                remove
            ])
            wave.run(sequence)
        }
    }
    
    private func removeSoundWaves() {
        children.compactMap { $0 as? SKShapeNode }.forEach { $0.removeFromParent() }
    }
    
    private func cleanup() {
        idleTimer?.invalidate()
        blinkTimer?.invalidate()
        removeAllActions()
        removeAllChildren()
    }
}

// MARK: - SwiftUI Integration
struct DozziCharacterView: UIViewRepresentable {
    @Binding var currentAnimation: DozziAnimation
    @Binding var mood: DozziMood
    
    var onAnimationComplete: (() -> Void)?
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        
        let scene = DozziCharacterScene()
        scene.size = CGSize(width: 200, height: 200)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        
        skView.presentScene(scene)
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? DozziCharacterScene else { return }
        
        scene.playAnimation(currentAnimation) { [weak self] in
            DispatchQueue.main.async {
                self?.onAnimationComplete?()
            }
        }
    }
}

// MARK: - Convenience Modifiers
extension DozziCharacterView {
    func onAnimationComplete(_ completion: @escaping () -> Void) -> DozziCharacterView {
        var view = self
        view.onAnimationComplete = completion
        return view
    }
}
```

## Integration with Existing Views

### **1. Paywall Integration**

```swift
struct PaywallHeaderView: View {
    @State private var dozziAnimation: DozziAnimation = .waving
    @State private var dozziMood: DozziMood = .happy
    
    var body: some View {
        VStack(spacing: 16) {
            DozziCharacterView(
                currentAnimation: $dozziAnimation,
                mood: $dozziMood
            )
            .frame(height: 120)
            .onAppear {
                // Greeting sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dozziAnimation = .excited
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    dozziAnimation = .idle
                }
            }
            
            VStack(spacing: 8) {
                Text("Hi! I'm Dozzi! ✨")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("I create magical bedtime stories just for your little one")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### **2. Story Creation Integration**

```swift
struct StoryCreationView: View {
    @State private var dozziAnimation: DozziAnimation = .idle
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            // Dozzi reacts to story generation
            DozziCharacterView(
                currentAnimation: $dozziAnimation,
                mood: .constant(.magical)
            )
            .frame(height: 100)
            
            Button("Create Story") {
                createStoryWithDozzi()
            }
        }
        .onChange(of: isGenerating) { generating in
            dozziAnimation = generating ? .magic : .idle
        }
    }
    
    private func createStoryWithDozzi() {
        dozziAnimation = .thinking
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dozziAnimation = .magic
            isGenerating = true
            
            // Your existing story creation logic
            createStory {
                isGenerating = false
                dozziAnimation = .celebrate
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    dozziAnimation = .idle
                }
            }
        }
    }
}
```

### **3. Story Reading Integration**

```swift
struct StoryReadingView: View {
    @State private var dozziAnimation: DozziAnimation = .reading
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            DozziCharacterView(
                currentAnimation: $dozziAnimation,
                mood: .constant(.sleepy)
            )
            .frame(width: 80, height: 80)
            
            VStack {
                // Story text
                // Audio controls
            }
        }
        .onChange(of: isPlaying) { playing in
            dozziAnimation = playing ? .listening : .reading
        }
    }
}
```

### **4. Settings/Profile Integration**

```swift
struct SettingsView: View {
    @State private var dozziAnimation: DozziAnimation = .idle
    
    var body: some View {
        VStack {
            DozziCharacterView(
                currentAnimation: $dozziAnimation,
                mood: .constant(.neutral)
            )
            .frame(height: 60)
            .onTapGesture {
                // Easter egg - Dozzi reacts to being tapped
                dozziAnimation = .excited
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dozziAnimation = .idle
                }
            }
            
            // Settings content
        }
    }
}
```

## Asset Requirements

### **Required Sprite Images**
```
Assets/Dozzi/
├── Characters/
│   ├── dozzi_body.png          # Main character body
│   ├── dozzi_nightcap.png      # Nightcap accessory
│   ├── dozzi_wand.png          # Magic wand
│   └── accessories/
│       ├── tiny_book.png       # Reading prop
│       ├── reading_glasses.png # Reading glasses
│       ├── thought_bubble.png  # Thinking bubble
│       └── rain_cloud.png      # Sad weather effect
├── Eyes/
│   ├── dozzi_eyes_open.png     # Default eyes
│   ├── dozzi_eyes_closed.png   # Blinking/sleeping
│   ├── dozzi_eyes_sleepy.png   # Drowsy eyes
│   ├── dozzi_eyes_sad.png      # Sad expression
│   ├── dozzi_eyes_wide.png     # Surprised/attentive
│   ├── dozzi_eyes_glow.png     # Magical glow
│   └── thinking_dots.png       # Animated dots for thought bubble
└── Particles/
    ├── DozziSparkles.sks       # Idle sparkle particles
    ├── DozziMagic.sks          # Magic generation particles
    ├── DozziCelebration.sks    # Celebration confetti
    ├── SleepParticles.sks      # Sleep Z particles
    └── RainParticles.sks       # Sad rain effect
```

### **Particle System Configurations**

#### **DozziSparkles.sks**
```
Particle System Properties:
- Birth Rate: 2-5 particles/second
- Lifetime: 1.5-2.0 seconds
- Emission Angle: 0-360 degrees
- Speed: 20-40 points/second
- Scale: 0.1-0.3
- Color: Soft yellow to white gradient
- Alpha: 0.8 to 0.0 fade
- Texture: Small star shape
```

#### **DozziMagic.sks**
```
Particle System Properties:
- Birth Rate: 30-50 particles/second
- Lifetime: 2.0-3.0 seconds
- Emission Angle: Radial burst
- Speed: 50-100 points/second
- Scale: 0.2-0.5
- Color: Rainbow spectrum
- Alpha: 1.0 to 0.0 fade
- Texture: Magic dust/sparkle
```

#### **DozziCelebration.sks**
```
Particle System Properties:
- Birth Rate: 100 particles/second (burst)
- Lifetime: 3.0-4.0 seconds
- Emission Angle: Upward cone (270° ± 45°)
- Speed: 100-200 points/second
- Scale: 0.3-0.8
- Color: Bright confetti colors
- Alpha: 1.0 to 0.0 fade
- Texture: Confetti shapes
```

## Performance Optimization

### **Memory Management**
```swift
class DozziCharacterManager: ObservableObject {
    private static let shared = DozziCharacterManager()
    private var activeScenes: [WeakReference<DozziCharacterScene>] = []
    
    func registerScene(_ scene: DozziCharacterScene) {
        activeScenes.append(WeakReference(scene))
        cleanupInactiveScenes()
    }
    
    private func cleanupInactiveScenes() {
        activeScenes = activeScenes.filter { $0.value != nil }
    }
    
    func pauseAllAnimations() {
        activeScenes.compactMap { $0.value }.forEach { scene in
            scene.isPaused = true
        }
    }
    
    func resumeAllAnimations() {
        activeScenes.compactMap { $0.value }.forEach { scene in
            scene.isPaused = false
        }
    }
}
```

### **Battery Life Considerations**
```swift
extension DozziCharacterScene {
    func enablePowerSavingMode() {
        // Reduce particle birth rates
        sparkleEmitter?.particleBirthRate = 1
        
        // Slower animation frame rates
        view?.preferredFramesPerSecond = 30
        
        // Simplify physics
        physicsWorld.speed = 0.8
    }
    
    func enableHighQualityMode() {
        sparkleEmitter?.particleBirthRate = 5
        view?.preferredFramesPerSecond = 60
        physicsWorld.speed = 1.0
    }
}
```

## Testing Strategy

### **Animation Testing**
```swift
class DozziCharacterTests: XCTestCase {
    func testAnimationTransitions() {
        let scene = DozziCharacterScene()
        let expectation = XCTestExpectation(description: "Animation completes")
        
        scene.playAnimation(.excited) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPerformanceWithMultipleCharacters() {
        measure {
            // Performance testing with multiple Dozzi instances
        }
    }
}
```

### **Memory Leak Testing**
```swift
func testMemoryLeaks() {
    weak var weakScene: DozziCharacterScene?
    
    autoreleasepool {
        let scene = DozziCharacterScene()
        weakScene = scene
        // Use scene
    }
    
    XCTAssertNil(weakScene, "Scene should be deallocated")
}
```

## Accessibility Support

### **VoiceOver Integration**
```swift
extension DozziCharacterView {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        // VoiceOver support
        skView.isAccessibilityElement = true
        skView.accessibilityLabel = "Dozzi, your bedtime story companion"
        skView.accessibilityHint = "Animated character that reacts to your story creation"
        
        return skView
    }
}
```

### **Reduced Motion Support**
```swift
extension DozziCharacterScene {
    private func setupAccessibility() {
        if UIAccessibility.isReduceMotionEnabled {
            // Use simpler, less intensive animations
            enableReducedMotionMode()
        }
    }
    
    private func enableReducedMotionMode() {
        // Replace complex animations with simple fades
        // Disable particle effects
        // Use static poses instead of continuous animation
    }
}
```

## Conclusion

This comprehensive SpriteKit character implementation brings Dozzi to life as an engaging, reactive companion throughout the bedtime story experience. The character serves multiple purposes:

1. **Brand Identity**: Creates a memorable mascot for the app
2. **User Engagement**: Provides emotional feedback and guidance
3. **Delight Factor**: Adds whimsical charm that appeals to both children and parents
4. **Functional Feedback**: Visually communicates app states and processes

The modular design allows for easy integration into existing SwiftUI views while maintaining performance and accessibility standards. Dozzi becomes an integral part of the user experience, making bedtime story creation feel magical and personal.