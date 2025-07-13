# Dozzi Character Asset Specifications

## Overview

This document provides detailed specifications for creating Dozzi character assets for the bedtime story app. These assets will replace the current placeholder graphics in the SpriteKit implementation.

## Character Design Requirements

### **Base Character Design**

**Overall Concept:**
- Friendly night owl character
- Soft, round, child-friendly appearance
- Cozy bedtime theme with pajamas and nightcap
- Gender-neutral design appealing to all children
- Age range: Appeals to children 2-10 years old

**Color Palette:**
```
Primary Colors:
- Body: Soft blue (#6BB6FF) to light purple (#B19CD9) gradient
- Pajamas: Star pattern on navy blue (#2C3E50) base
- Nightcap: Deep purple (#8E44AD) with lighter purple (#BB8FCE) trim

Accent Colors:
- Eyes: Bright white (#FFFFFF) with black pupils
- Wand: Brown handle (#8B4513), golden star tip (#FFD700)
- Sparkles: Yellow (#FFD700) to white (#FFFFFF) gradient

Supporting Colors:
- Blush/cheeks: Soft pink (#FFB6C1)
- Inner mouth: Dark pink (#FF69B4)
- Shadow/outline: Dark blue (#1B4F72)
```

### **Required Asset Files**

#### **1. Main Character Components**

**File: `dozzi_body.png`**
- Size: 200x200 pixels at 3x resolution (600x600 actual)
- Format: PNG with transparency
- Content: Main owl body in pajamas
- Features:
  - Round, soft owl body
  - Star-patterned pajamas
  - Subtle shadow beneath for depth
  - No eyes (separate asset for animation)
  - Small beak or cute facial features

**File: `dozzi_nightcap.png`**
- Size: 150x180 pixels at 3x resolution (450x540 actual)
- Format: PNG with transparency
- Content: Floppy nightcap
- Features:
  - Oversized, slightly droopy cap
  - Small bell at the tip
  - Soft fabric texture
  - Should layer nicely on top of head

**File: `dozzi_wand.png`**
- Size: 80x120 pixels at 3x resolution (240x360 actual)
- Format: PNG with transparency
- Content: Magic wand
- Features:
  - Wooden handle with grain texture
  - Golden star at tip
  - Slight magical glow around star
  - Proportioned for character's hand/wing

#### **2. Eye Expressions (Critical for Animation)**

**File: `dozzi_eyes_open.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Default open eyes with pupils
- Features: Alert, friendly expression

**File: `dozzi_eyes_closed.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Closed eyes for blinking
- Features: Peaceful, content expression

**File: `dozzi_eyes_sleepy.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Half-closed, drowsy eyes
- Features: Heavy eyelids, sleepy expression

**File: `dozzi_eyes_sad.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Downturned, sad eyes
- Features: Slightly droopy, sympathetic expression

**File: `dozzi_eyes_wide.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Wide, surprised/attentive eyes
- Features: Larger pupils, alert expression

**File: `dozzi_eyes_glow.png`**
- Size: 100x40 pixels at 3x resolution (300x120 actual)
- Content: Magical glowing eyes
- Features: Cyan/blue glow, mystical appearance

#### **3. Props and Accessories**

**File: `tiny_book.png`**
- Size: 40x30 pixels at 3x resolution (120x90 actual)
- Content: Small book for reading animation
- Features: Miniature storybook with visible pages

**File: `reading_glasses.png`**
- Size: 80x25 pixels at 3x resolution (240x75 actual)
- Content: Small reading glasses
- Features: Round, scholarly glasses

**File: `thought_bubble.png`**
- Size: 80x60 pixels at 3x resolution (240x180 actual)
- Content: Speech/thought bubble
- Features: Classic comic-style bubble with tail

**File: `thinking_dots.png`**
- Size: 45x15 pixels at 3x resolution (135x45 actual)
- Content: Three animated dots for thought bubble
- Features: Three small circles in a row

**File: `rain_cloud.png`**
- Size: 120x60 pixels at 3x resolution (360x180 actual)
- Content: Small sad rain cloud
- Features: Gray cloud with rain drops

#### **4. Alternative Character Poses (Optional Enhancement)**

**File: `dozzi_body_excited.png`**
- Slightly different pose showing excitement
- Arms/wings positioned differently

**File: `dozzi_body_sleepy.png`**
- More relaxed, droopy posture
- Slumped shoulders, relaxed position

**File: `dozzi_body_magical.png`**
- Dynamic pose with wand raised
- More energetic stance

## Particle System Assets

### **Sparkle Particle**

**File: `spark.png`**
- Size: 32x32 pixels at 3x resolution (96x96 actual)
- Format: PNG with transparency
- Content: 4-pointed star sparkle
- Features:
  - Golden yellow center
  - White outer glow
  - Soft, magical appearance
  - Works well when scaled down

### **Magic Dust Particle**

**File: `magic_dust.png`**
- Size: 24x24 pixels at 3x resolution (72x72 actual)
- Format: PNG with transparency
- Content: Small magical dust mote
- Features:
  - Shimmering appearance
  - Cyan/blue coloring
  - Soft edges

### **Confetti Particles**

**Files: `confetti_1.png`, `confetti_2.png`, `confetti_3.png`**
- Size: 20x20 pixels at 3x resolution (60x60 actual)
- Format: PNG with transparency
- Content: Small confetti pieces in different shapes
- Features:
  - Bright, celebratory colors
  - Rectangle, circle, and triangle shapes
  - Festive appearance

## Technical Specifications

### **General Requirements**

1. **Resolution**: All assets must be provided at 3x resolution for Retina displays
2. **Format**: PNG with alpha transparency
3. **Color Space**: sRGB color space
4. **Compression**: Optimize for file size while maintaining quality
5. **Naming**: Use exact filenames as specified for code compatibility

### **Design Guidelines**

1. **Consistency**: All assets should maintain the same art style and color palette
2. **Scalability**: Assets should look good when scaled between 50% and 150% of original size
3. **Contrast**: Ensure good contrast for accessibility
4. **Child-Friendly**: Soft, rounded edges; avoid sharp or scary elements
5. **Animation-Ready**: Assets should work well in motion and transitions

### **Layer Organization (For Designers)**

```
Dozzi Character Layers:
├── Background/Shadow
├── Body/Pajamas
├── Arms/Wings (if separate)
├── Eyes (various expressions)
├── Nightcap
├── Accessories (wand, props)
├── Effects/Highlights
└── Outline (if used)
```

## Asset Integration Notes

### **Current Placeholder System**
The current implementation uses simple colored shapes as placeholders:
- Blue circle for body
- Brown rectangle for wand
- Purple triangle for nightcap
- White rectangles for eyes

### **Asset Replacement Process**
1. Add new assets to `Assets.xcassets` in Xcode
2. Update `DozziCharacterScene.swift` to use new asset filenames
3. Adjust positioning and scaling as needed for new proportions
4. Test all animations with new assets

### **File Organization in Xcode**
```
Assets.xcassets/
├── Dozzi/
│   ├── Character/
│   │   ├── dozzi_body.imageset/
│   │   ├── dozzi_nightcap.imageset/
│   │   └── dozzi_wand.imageset/
│   ├── Eyes/
│   │   ├── dozzi_eyes_open.imageset/
│   │   ├── dozzi_eyes_closed.imageset/
│   │   └── [other eye expressions]
│   ├── Props/
│   │   ├── tiny_book.imageset/
│   │   └── [other props]
│   └── Particles/
│       ├── spark.imageset/
│       └── [other particles]
```

## Animation Considerations

### **Eye Animation Requirements**
- Eyes must align perfectly when swapping between expressions
- Consistent positioning across all eye assets
- Smooth transitions between states

### **Modular Design Benefits**
- Separate components allow for independent animation
- Mix and match expressions with body poses
- Easier to add new animations later

### **Performance Optimization**
- Keep texture sizes reasonable for mobile performance
- Use texture atlases for related assets if needed
- Consider using vector graphics for simple shapes

## Design Inspiration and References

### **Character Personality Traits**
- **Wise but Playful**: Like a gentle teacher who makes learning fun
- **Sleepy but Alert**: Ready for bedtime but excited about stories
- **Magical but Safe**: Mystical powers used only for good
- **Friendly but Respectful**: Warm personality that respects boundaries

### **Visual References**
- Classic children's book illustrations
- Studio Ghibli character design principles (soft, round, approachable)
- Modern app mascots (Duolingo owl, but more bedtime-themed)
- Traditional bedtime imagery (stars, moons, cozy textures)

### **Animation Style Goals**
- Smooth, gentle movements (no jarring or fast motions)
- Bouncy but not hyperactive
- Magical effects that enhance rather than distract
- Bedtime-appropriate pacing and energy

## Delivery Format

### **Final Asset Package**
Please deliver assets in the following structure:
```
Dozzi_Assets_v1.0/
├── Character/
│   ├── dozzi_body@3x.png
│   ├── dozzi_nightcap@3x.png
│   └── dozzi_wand@3x.png
├── Eyes/
│   ├── dozzi_eyes_open@3x.png
│   ├── dozzi_eyes_closed@3x.png
│   ├── dozzi_eyes_sleepy@3x.png
│   ├── dozzi_eyes_sad@3x.png
│   ├── dozzi_eyes_wide@3x.png
│   └── dozzi_eyes_glow@3x.png
├── Props/
│   ├── tiny_book@3x.png
│   ├── reading_glasses@3x.png
│   ├── thought_bubble@3x.png
│   ├── thinking_dots@3x.png
│   └── rain_cloud@3x.png
├── Particles/
│   ├── spark@3x.png
│   ├── magic_dust@3x.png
│   ├── confetti_1@3x.png
│   ├── confetti_2@3x.png
│   └── confetti_3@3x.png
├── Source_Files/
│   └── [Original design files - .sketch, .psd, .ai, etc.]
└── Documentation/
    └── Asset_Notes.txt
```

### **Timeline Estimate**
- **Character Design Concept**: 2-3 days
- **Asset Creation**: 5-7 days
- **Revisions and Polish**: 2-3 days
- **Total Estimated Time**: 9-13 days

### **Revision Process**
1. Initial concept approval
2. First asset delivery
3. Integration testing and feedback
4. Final revisions and polish
5. Delivery of final assets

## Success Criteria

The final Dozzi character assets should:
1. **Engage Children**: Immediately appealing to young audiences
2. **Convey Personality**: Clear, friendly, magical character
3. **Animate Smoothly**: All components work well in motion
4. **Scale Appropriately**: Look good at different sizes
5. **Maintain Performance**: Don't impact app performance
6. **Support Brand**: Reinforce the bedtime story app experience

This character will become the face of the app and should create an emotional connection with both children and parents, making bedtime story time feel special and magical.