# KB SOLAR CRM - COLOR USAGE GUIDE & QUICK REFERENCE
## Complete Development Guide for Consistent Color Usage

---

## 📱 QUICK START FOR DEVELOPERS

### Copy-Paste Color Snippets

#### Common Button Styles
```dart
// Primary Action Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonPrimary,
    foregroundColor: AppColors.buttonText,
  ),
  onPressed: () {},
  child: const Text('Action'),
)

// Secondary Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.primary),
    foregroundColor: AppColors.primary,
  ),
  onPressed: () {},
  child: const Text('Cancel'),
)

// Danger Button (Delete, etc.)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
  ),
  onPressed: () {},
  child: const Text('Delete'),
)
```

#### Common Text Styles
```dart
// Heading Text
Text('Page Title',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  ),
)

// Subtitle/Secondary Text
Text('Subtitle',
  style: TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  ),
)

// Muted/Hint Text
Text('Helper text',
  style: TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
  ),
)
```

#### Common Card/Container
```dart
// Standard Card
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.borderPrimary),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: const Text('Content here'),
)
```

#### Common Input Field
```dart
// Text Input
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.inputBg,
    hintText: 'Enter text...',
    hintStyle: TextStyle(color: AppColors.inputPlaceholder),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.inputBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.inputBorderFocus,
        width: 2,
      ),
    ),
  ),
)
```

#### Common Status Display
```dart
// Success Message
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.successLight,
    border: Border.all(color: AppColors.success),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Success!', style: TextStyle(color: AppColors.success)),
)

// Error Message
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.errorLight,
    border: Border.all(color: AppColors.error),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Error!', style: TextStyle(color: AppColors.error)),
)

// Warning Message
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.warningLight,
    border: Border.all(color: AppColors.warning),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Warning!', style: TextStyle(color: AppColors.warning)),
)
```

---

## 🎨 COLOR USAGE MATRIX

### By Component Type

#### Buttons
| Type | Background | Text | Border | Hover |
|------|-----------|------|--------|-------|
| **Primary** | `buttonPrimary` | `buttonText` (white) | — | `buttonPrimaryHover` |
| **Secondary** | `buttonSecondary` | `buttonSecondaryText` | `primary` | `primaryLighter` |
| **Danger** | `error` | `white` | — | darkened error |
| **Success** | `success` | `white` | — | darkened success |

#### Text
| Context | Color | Size | Weight |
|---------|-------|------|--------|
| **Main Heading** | `textPrimary` | 20 | Bold |
| **Subheading** | `textPrimary` | 16 | Semi-bold |
| **Body Text** | `textPrimary` | 14 | Normal |
| **Secondary Info** | `textSecondary` | 14 | Normal |
| **Hints/Labels** | `textTertiary` | 12 | Normal |
| **Disabled Text** | `textLight` | 14 | Normal |

#### Containers/Cards
| Purpose | Background | Border | Shadow |
|---------|-----------|--------|--------|
| **Main Card** | `bgSurface` | `borderPrimary` | light |
| **Active Item** | `primaryLightest` | `borderPrimary` | light |
| **Hover Item** | `bgHover` | `borderSecondary` | medium |
| **Disabled Item** | `bgDisabled` | `borderLight` | none |

#### Input Fields
| State | Border | Background | Text |
|-------|--------|-----------|------|
| **Normal** | `inputBorder` | `inputBg` | `inputText` |
| **Focused** | `inputBorderFocus` | `inputBg` | `inputText` |
| **Error** | `inputError` | `inputBg` | `error` |
| **Success** | `inputSuccess` | `inputBg` | `success` |
| **Disabled** | `borderLight` | `bgDisabled` | `textLight` |

#### Navigation/Sidebar
| State | Background | Text | Icon |
|-------|-----------|------|------|
| **Active** | `sidebarItemActive` | `sidebarTextActive` | `iconPrimary` |
| **Inactive** | `sidebarBg` | `sidebarTextInactive` | `iconSecondary` |
| **Hover** | `sidebarItemHover` | `sidebarTextInactive` | `iconPrimary` |
| **Disabled** | `bgDisabled` | `textLight` | `iconDisabled` |

#### Status Indicators
| Status | Color | Light Background | Usage |
|--------|-------|-----------------|-------|
| **Success** | `success` (#10B981) | `successLight` | Completed, approved |
| **Error** | `error` (#EF4444) | `errorLight` | Failed, rejected |
| **Warning** | `warning` (#F59E0B) | `warningLight` | Pending, attention |
| **Info** | `info` (#3B82F6) | `infoLight` | Notifications |

---

## 📋 DO's AND DON'Ts

### ✅ DO

```dart
// ✅ GOOD: Use semantic color constants
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonPrimary,
  ),
  child: const Text('Submit'),
)

// ✅ GOOD: Use opacity helpers
Container(
  color: AppColors.logoShadowWithOpacity(0.15),
)

// ✅ GOOD: Use state-based helpers
BorderSide(
  color: AppColors.getBorderColor(
    isFocused: isFocused,
    hasError: hasError,
  ),
)

// ✅ GOOD: Group related colors in a section
Column(
  children: [
    Text('Title', style: TextStyle(color: AppColors.textPrimary)),
    Text('Subtitle', style: TextStyle(color: AppColors.textSecondary)),
    Text('Hint', style: TextStyle(color: AppColors.textTertiary)),
  ],
)

// ✅ GOOD: Create semantic color combinations
BoxDecoration(
  color: AppColors.bgSurface,
  border: Border.all(color: AppColors.borderPrimary),
  boxShadow: [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 8,
    ),
  ],
)
```

### ❌ DON'T

```dart
// ❌ BAD: Don't hardcode colors
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF9F5BFF),  // ❌ HARDCODED
  ),
  child: const Text('Submit'),
)

// ❌ BAD: Don't use Material Colors directly
Text('Text', style: TextStyle(color: Colors.grey))  // ❌ USE AppColors.textSecondary

// ❌ BAD: Don't mix color sources
Container(
  color: const Color(0xFF5535D4),  // ❌ HARDCODED
  border: Border.all(color: AppColors.borderPrimary),  // ✅ CORRECT
)

// ❌ BAD: Don't create new color variants
BoxShadow(
  color: const Color(0xFF9F5BFF).withOpacity(0.25),  // ❌ USE AppColors.primaryWithOpacity()
)

// ❌ BAD: Don't repeat color definitions
Container(
  color: const Color(0xFF1E1F3B),  // ❌ USE AppColors.textPrimary
  child: Text('Title', style: TextStyle(color: Colors.white)),
)
```

---

## 🎯 COLOR USAGE BY SCREEN TYPE

### Dashboard Screens
```dart
// Main dashboard structure
Scaffold(
  backgroundColor: AppColors.bgPrimary,
  appBar: AppBar(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.buttonText,
  ),
  body: Column(
    children: [
      // Header cards - use bgSurface with borderPrimary
      // Status cards - use respective status colors
      // Data lists - alternating bgSurface and bgHover
    ],
  ),
)
```

### Form Screens
```dart
// Login, Sign-up, Edit screens
Scaffold(
  backgroundColor: AppColors.bgPrimary,
  body: Form(
    child: Column(
      children: [
        // Heading: textPrimary
        // Labels: textSecondary
        // Input fields: inputBorder, inputBg
        // Buttons: buttonPrimary
        // Error text: error
      ],
    ),
  ),
)
```

### Detail/List Screens
```dart
// Lead details, Installation details
ListView(
  children: [
    // Header: bgSurface, borderPrimary
    // Status badge: success/warning/error
    // List items: alternating bgSurface and bgHover
    // Action buttons: primary/secondary
  ],
)
```

### Navigation Sidebars
```dart
// Sidebar structure
Container(
  color: AppColors.sidebarBg,
  border: Border(right: BorderSide(color: AppColors.sidebarBorder)),
  child: Column(
    children: [
      // Active item: sidebarItemActive bg, sidebarTextActive color
      // Inactive item: sidebarBg, sidebarTextInactive color
      // Hover item: sidebarItemHover bg
    ],
  ),
)
```

---

## 🔍 FINDING HARDCODED COLORS

### Search patterns (use Find in IDE):
```
// Search for these patterns to find hardcoded colors:
Color(0xFF  // Most common hardcoded colors
Colors.grey
Colors.purple
Colors.blue
Colors.red
withOpacity(  // Custom opacity on hardcoded colors
```

### Replace patterns:
```
0xFF9F5BFF        → AppColors.primary
0xFF5535D4        → AppColors.accent2
0xFF7B61FF        → AppColors.accent1
0xFF1E1F3B        → AppColors.textPrimary
0xFF64748B        → AppColors.textSecondary
0xFFF5F0FF        → AppColors.bgPrimary
0xFFEDE9FE        → AppColors.primaryLighter
Colors.white      → AppColors.white (or use directly)
Colors.red        → AppColors.error
Colors.green      → AppColors.success
Colors.orange     → AppColors.warning
Colors.blue       → AppColors.info
```

---

## 🚀 IMPLEMENTATION WORKFLOW

### For New Screens:
1. Copy `TEMPLATE_NEW_SCREEN.dart`
2. Replace `[SCREEN_NAME]` and `[DESCRIPTION]`
3. Implement using color snippets from above
4. Test on different screen sizes
5. Verify no hardcoded colors used

### For Existing Screens:
1. Open screen file
2. Find all `Color(0xFF...` instances
3. Replace with appropriate `AppColors.*` constant
4. Find all `Colors.*` instances
5. Replace with appropriate `AppColors.*` constant
6. Verify file builds without errors

### Before Committing:
- [ ] No hardcoded colors remain
- [ ] All text is readable (contrast check)
- [ ] Status indicators use correct colors
- [ ] Buttons follow button styling rules
- [ ] Cards follow card styling rules
- [ ] File imported `AppColors` correctly

---

## 📞 COLOR REFERENCE QUICK LOOKUP

| Need | Color Constant | Hex | Usage |
|------|---|---|---|
| Main button | `buttonPrimary` | #9F5BFF | Action buttons |
| Main text | `textPrimary` | #1E1F3B | Headings, body |
| Page background | `bgPrimary` | #F5F0FF | Scaffold bg |
| Card background | `bgSurface` | #FFFFFF | Card containers |
| Border line | `borderPrimary` | #E6D5FF | Card borders |
| Success state | `success` | #10B981 | Approved, done |
| Error state | `error` | #EF4444 | Failed, invalid |
| Warning state | `warning` | #F59E0B | Pending, caution |
| Sidebar background | `sidebarBg` | #F5F0FF | Sidebar |
| Sidebar active | `sidebarItemActive` | #9F5BFF | Active nav |
| Input border | `inputBorder` | #E6D5FF | Normal input |
| Input border focus | `inputBorderFocus` | #9F5BFF | Focused input |
| Muted text | `textSecondary` | #64748B | Secondary text |
| Very light text | `textTertiary` | #94A3B8 | Hints, labels |
| Light background | `bgHover` | #EFE7FF | Hover states |
| Light background | `primaryLightest` | #F5F0FF | Subtle fills |
| Logo shadow | `logoShadow` | #9F5BFF | Shadow effects |

---

## 🎓 TRAINING NOTES

### Color Philosophy
- **Purple Spectrum**: Logo color `#9F5BFF` is the heart of the design
- **Light Tints**: For subtle backgrounds and inactive states
- **Gray Scale**: For text at multiple hierarchy levels
- **Status Colors**: Green/Red/Orange for semantic meaning
- **Consistency**: Same purpose = same color everywhere

### Why This Matters
- **Brand Recognition**: All purple = your logo
- **Professional Look**: Consistent colors = polished UI
- **User Experience**: Predictable colors = intuitive interface
- **Maintenance**: Centralized colors = easy updates
- **Accessibility**: Proper contrast = readable for all

---

## ✨ EXAMPLE: COMPLETE FORM SCREEN

```dart
import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_colors.dart';

class ExampleFormScreen extends StatefulWidget {
  const ExampleFormScreen({super.key});

  @override
  State<ExampleFormScreen> createState() => _ExampleFormScreenState();
}

class _ExampleFormScreenState extends State<ExampleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,  // ← Light purple background
      appBar: AppBar(
        backgroundColor: AppColors.primary,  // ← Logo purple
        foregroundColor: AppColors.buttonText,  // ← White text
        title: const Text('Example Form'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              Text(
                'Fill Out Form',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,  // ← Dark text
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Please provide your details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,  // ← Muted text
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBg,  // ← White background
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: AppColors.inputPlaceholder),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.inputBorderFocus,  // ← Logo purple on focus
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Name is required';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              const SizedBox(height: 16),

              // Email field
              Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBg,
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: AppColors.inputPlaceholder),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.inputBorderFocus,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  return null;
                },
                onSaved: (value) => _email = value,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,  // ← Logo purple
                    foregroundColor: AppColors.buttonText,  // ← White text
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.buttonText,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      setState(() => _isSubmitting = true);
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Form submitted!',
                style: TextStyle(color: AppColors.success),
              ),
              backgroundColor: AppColors.successLight,
            ),
          );
        }
      });
    }
  }
}
```

---

**Last Updated**: 2026-05-04
**Design System Version**: 1.0
**Primary Color**: #9F5BFF (Logo Purple)
