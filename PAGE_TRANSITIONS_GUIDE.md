# Page Transition Animations Guide

## Overview

The Lotto Runners app now includes smooth, professional page transition animations throughout. This guide explains how the animations work and how to use them.

## ✅ What's Been Added

### 1. **Global Page Transitions**
- Added to `lib/theme.dart`
- Automatically applied to ALL Navigator.push() calls
- Platform-specific animations:
  - **Android/Windows/Linux**: Fade upwards transition
  - **iOS/macOS**: Cupertino (iOS-style) transition
  
### 2. **Custom Transition Utility**
- Created `lib/utils/page_transitions.dart`
- Provides multiple transition styles for special cases
- Easy-to-use extension methods

## 🎨 Available Transition Styles

### 1. **Default (Global)**
```dart
// This now has animation automatically!
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => MyPage()),
);
```

### 2. **Slide From Right**
```dart
Navigator.push(
  context,
  PageTransitions.slideFromRight(MyPage()),
);

// Or using extension:
context.pushWithSlide(MyPage());
```

### 3. **Slide From Bottom**
```dart
Navigator.push(
  context,
  PageTransitions.slideFromBottom(MyPage()),
);

// Or using extension:
context.pushWithSlideUp(MyPage());
```

### 4. **Fade Transition**
```dart
Navigator.push(
  context,
  PageTransitions.fade(MyPage()),
);

// Or using extension:
context.pushWithFade(MyPage());
```

### 5. **Scale (Zoom) Transition**
```dart
Navigator.push(
  context,
  PageTransitions.scale(MyPage()),
);

// Or using extension:
context.pushWithScale(MyPage());
```

### 6. **Slide and Fade (Recommended)**
```dart
Navigator.push(
  context,
  PageTransitions.slideAndFade(MyPage()),
);

// Or using extension (recommended):
context.pushAnimated(MyPage());
```

### 7. **Modal/Dialog Style**
```dart
Navigator.push(
  context,
  PageTransitions.modal(MyPage()),
);

// Or using extension:
context.pushModal(MyPage());
```

### 8. **Material 3 Style**
```dart
// Shared axis (Material 3 recommendation)
Navigator.push(
  context,
  Material3Transitions.sharedAxisX(MyPage()),
);

// Fade through (Material 3 recommendation)
Navigator.push(
  context,
  Material3Transitions.fadeThrough(MyPage()),
);
```

## 📱 Usage Examples

### Example 1: Standard Navigation
```dart
// Old way (still works, now with animation):
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfilePage()),
);

// New way (recommended):
context.pushAnimated(ProfilePage());
```

### Example 2: Modal-Style Pages
```dart
// For settings, filters, or dialog-like pages
context.pushModal(SettingsPage());
```

### Example 3: Bottom Sheet Style
```dart
// For pages that should slide up from bottom
context.pushWithSlideUp(FilterPage());
```

### Example 4: Replace Current Page
```dart
// Replace with animation
context.pushReplacementAnimated(NewPage());
```

### Example 5: Clear Stack and Navigate
```dart
// Go to home and clear all previous pages
context.pushAndRemoveUntilAnimated(
  HomePage(),
  (route) => false,
);
```

## 🎯 Best Practices

### When to Use Which Transition

| Transition | Best For | Example Use Case |
|------------|----------|------------------|
| **Default (Global)** | Most pages | Standard navigation between screens |
| **Slide from Right** | Detailed views | List item → Details page |
| **Slide from Bottom** | Secondary actions | Filters, Settings, Add forms |
| **Fade** | Related content | Switching tabs, Similar pages |
| **Scale** | Modal content | Popups, Confirmations |
| **Slide and Fade** | Premium feel | Profile, Important pages |
| **Modal** | Overlays | Settings, Filters, Info |
| **Material 3** | Modern look | All pages (if you prefer) |

### Recommended Usage

1. **Default Navigation** (95% of cases):
   ```dart
   context.pushAnimated(MyPage());
   ```

2. **Modal/Settings Pages**:
   ```dart
   context.pushModal(SettingsPage());
   ```

3. **Forms/Filters** (bottom entry):
   ```dart
   context.pushWithSlideUp(AddErrandPage());
   ```

## 🔧 Customization

### Change Transition Duration
```dart
// In PageTransitions class, modify:
transitionDuration: const Duration(milliseconds: 300), // Default
// Change to 200 for faster, 400 for slower
```

### Change Curves
```dart
// In PageTransitions class, modify:
const curve = Curves.easeInOutCubic; // Default
// Try: easeOut, easeIn, fastOutSlowIn, etc.
```

### Create Custom Transition
```dart
static Route<T> customTransition<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Your custom animation here
      return child;
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
```

## ⚡ Performance

### Optimization Tips

1. **Use `const` constructors** for pages when possible
2. **Avoid heavy computations** in page builders
3. **Preload images** before transitioning
4. **Keep transitions short** (200-400ms)

### Transition Duration Guidelines

- **Fast (200ms)**: Simple fades, quick actions
- **Medium (300ms)**: Standard transitions (recommended)
- **Slow (400-500ms)**: Complex or special effects
- **Never > 600ms**: Users will feel lag

## 🎭 Animation Details

### What Happens Automatically

✅ **All MaterialPageRoute navigations now animate**
✅ **Platform-specific transitions** (iOS vs Android)
✅ **Back button animations** (reverse of forward)
✅ **Hero animations** still work
✅ **Gesture navigation** (swipe back on iOS)

### What You Need to Do

Nothing! All existing navigation code now has animations.

For special cases, use the extension methods:
```dart
// Instead of:
Navigator.push(context, MaterialPageRoute(builder: (context) => MyPage()));

// Use:
context.pushAnimated(MyPage());
```

## 🚀 Migration Guide

### Update Existing Code

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfilePage()),
);
```

**After (Option 1 - No change needed):**
```dart
// Still works, now with animation!
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfilePage()),
);
```

**After (Option 2 - Recommended):**
```dart
// Cleaner syntax
context.pushAnimated(ProfilePage());
```

### Special Cases

**Slide up from bottom (for modals):**
```dart
// Before
showModalBottomSheet(...)

// Alternative (full page)
context.pushWithSlideUp(MyPage());
```

**Modal style (semi-transparent background):**
```dart
// Before
showDialog(...)

// Alternative (full page)
context.pushModal(MyPage());
```

## 📊 Comparison

### Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| Visual | Instant/jarring | Smooth/animated |
| Feel | Basic | Professional |
| Code | Standard | Enhanced |
| Performance | Same | Same (optimized) |
| Platforms | Generic | Platform-specific |

## 🎬 Demo

The animations are visible throughout the app:

1. **Login → Home**: Fade upwards
2. **Home → Profile**: Slide and fade
3. **List → Details**: Slide from right
4. **Settings/Filters**: Slide from bottom
5. **Back Navigation**: Reverse animation

## 🐛 Troubleshooting

### Animation Not Showing

1. Check if using `MaterialPageRoute` (should auto-animate)
2. Verify Flutter version supports page transitions
3. Ensure theme is applied in MaterialApp

### Animation Too Fast/Slow

Adjust duration in `page_transitions.dart`:
```dart
transitionDuration: const Duration(milliseconds: 300),
```

### Animation Feels Janky

1. Reduce complexity of destination page
2. Use `const` constructors
3. Preload heavy resources
4. Check device performance

## 📚 Additional Resources

- [Flutter Animations](https://flutter.dev/docs/development/ui/animations)
- [Material Motion](https://material.io/design/motion)
- [PageTransitionBuilder](https://api.flutter.dev/flutter/widgets/PageTransitionsBuilder-class.html)

## ✨ Summary

- ✅ **Global animations** added to all pages
- ✅ **Custom transitions** available for special cases
- ✅ **Easy-to-use** extension methods
- ✅ **Platform-specific** behavior
- ✅ **Performant** and smooth
- ✅ **Backwards compatible** - no breaking changes!

### Quick Reference

```dart
// Most common usages:
context.pushAnimated(MyPage());           // General purpose
context.pushModal(ModalPage());           // Settings/filters
context.pushWithSlideUp(FormPage());      // Bottom entry
context.pushReplacementAnimated(Home());  // Replace current
```

---

**Enjoy the smooth transitions! 🎉**

