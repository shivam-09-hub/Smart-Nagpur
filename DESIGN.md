# Design System & UI/UX Guidelines — Smart Nagpur

This document specifies the visual identity, design tokens, color palette, typography hierarchy, component guidelines, and Stitch design alignment protocol for the **Smart Nagpur** application suite.

---

## 1. Design Philosophy & Visual Identity

Smart Nagpur delivers an intuitive, accessible, and modern civic interface tailored for Indian municipal governance. It combines clean Material 3 principles with purposeful civic color accents, ensuring high legibility in bright outdoor sunlight and effortless navigation for diverse citizen demographics.

### Core Principles
1. **Civic Clarity:** High visual contrast, clear typographic hierarchy, and unambiguous status communication.
2. **Contextual Color Coding:** 10 distinct service color accents to immediately orient users within specific civic departments.
3. **Touch-Friendly & Accessible:** Minimum touch targets of 48dp on all interactive elements; high contrast text meeting WCAG AA standards.
4. **Resilient Feedback:** Every user action provides immediate visual feedback (loading spinners, progress indicators, subtle elevation shadows, clear error alerts).

---

## 2. Color Palette & Design Tokens

All colors are centralized in `lib/core/theme/app_tokens.dart` under the `AppColors` class.

### 2.1. Brand & Surface Colors

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `AppColors.primary` | `#0B5EA8` | Deep civic navy blue. Used for app bars, primary action buttons, selected navigation icons. |
| `AppColors.primaryDark` | `#07477F` | Darker blue shade used for headers, active states, and elevated contrast areas. |
| `AppColors.primarySoft` | `#E6F1FA` | Soft tinted blue background for primary badges, active chip highlights, and banners. |
| `AppColors.secondary` | `#00A884` | Fresh civic teal green. Used for secondary actions, verified badges, and positive prompts. |
| `AppColors.secondarySoft`| `#E2F7F2` | Soft teal background for success chips and secondary accents. |
| `AppColors.background` | `#F7F9FC` | Off-white, soft cool gray page canvas. Reduces eye strain. |
| `AppColors.surface` | `#FFFFFF` | Pure white background for cards, modal dialogs, and bottom sheets. |
| `AppColors.surfaceMuted`| `#F0F4F8` | Subtle gray container fill for inactive inputs, table headers, and dividers. |
| `AppColors.border` | `#DDE4EC` | Neutral stroke for outlines, borders, and text fields. |
| `AppColors.divider` | `#E8EDF3` | Hairline separators between list items and card sections. |

### 2.2. Text Hierarchy Colors

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `AppColors.textPrimary` | `#152536` | Dark navy-charcoal. Primary headings, titles, body text, and active input labels. |
| `AppColors.textSecondary` | `#53677B` | Medium slate. Subtitles, metadata, form labels, and descriptive paragraphs. |
| `AppColors.textMuted` | `#7B8C9D` | Light slate. Timestamps, captions, placeholder text, and inactive tab labels. |
| `AppColors.onPrimary` | `#FFFFFF` | Pure white text on primary filled buttons and colored badges. |

### 2.3. Semantic & Feedback Colors

| Status | Main Token | Main Hex | Soft Background Token | Soft Hex | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Success** | `AppColors.success` | `#18864B` | `AppColors.successSoft` | `#E5F5EC` | Resolved complaints, approved vendor permits, verified states. |
| **Warning** | `AppColors.warning` | `#E09800` | `AppColors.warningSoft` | `#FFF4D6` | Under review, pending verification, expiring permits, alerts. |
| **Error** | `AppColors.error` | `#C53B3B` | `AppColors.errorSoft` | `#FCE8E8` | Rejected items, validation errors, suspended accounts, failed uploads. |
| **Info** | `AppColors.info` | `#2176C7` | `AppColors.infoSoft` | `#E7F1FB` | Informational advisories, location tips, general status notices. |

---

## 3. Civic Service Accent Colors

Each of the 10 municipal service categories is assigned an intentional accent color defined in `AppColors` and mapped via `ServiceTheme`:

```
┌─────────────────┬──────────────────┬─────────────────┬─────────────────┐
│ Vendor          │ Garbage          │ Water           │ Roads           │
│ #246BCE (Blue)  │ #238B57 (Green)  │ #078EB8 (Cyan)  │ #E07C16 (Amber) │
├─────────────────┼──────────────────┼─────────────────┼─────────────────┤
│ Animals         │ Drainage         │ Streetlights    │ Public Spaces   │
│ #8056C7 (Purple)│ #3E4DB4 (Indigo) │ #D59800 (Gold)  │ #00897B (Teal)  │
├─────────────────┼──────────────────┴─────────────────┴─────────────────┤
│ Encroachment    │ Other Civic Issues                                   │
│ #D5534C (Coral) │ #64748B (Slate Gray)                                 │
└─────────────────┴──────────────────────────────────────────────────────┘
```

- **Vendor (`#246BCE`):** Commercial vibrancy, official trade permissions.
- **Garbage (`#238B57`):** Cleanliness, environmental sanitation, waste management.
- **Water (`#078EB8`):** Clean municipal water supply, pipeline infrastructure.
- **Roads (`#E07C16`):** Construction, asphalt, traffic caution, pothole repairs.
- **Animals (`#8056C7`):** Veterinary care, stray animal rehabilitation.
- **Drainage (`#3E4DB4`):** Stormwater, underground sewage, sanitation engineering.
- **Streetlights (`#D59800`):** Illumination, electrical safety, night visibility.
- **Public Spaces (`#00897B`):** Municipal parks, gardens, playgrounds, civic grounds.
- **Encroachment (`#D5534C`):** Unauthorized occupation, legal enforcement, right of way.
- **Other (`#64748B`):** General municipal queries and miscellaneous complaints.

---

## 4. Typography Scale

The application uses **Roboto** as its primary typeface, configured across standardized scales in `AppTypography`:

| Scale Name | Size | Line Height | Weight | Letter Spacing | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AppTypography.display` | 32sp | 1.18 | 700 (Bold) | -0.7 | Splash hero titles, major metric highlights. |
| `AppTypography.headline`| 24sp | 1.25 | 700 (Bold) | -0.35 | Screen titles, onboarding headings. |
| `AppTypography.titleLarge`| 20sp | 1.30 | 700 (Bold) | Normal | Section headers, card main titles. |
| `AppTypography.title` | 17sp | 1.35 | 600 (Semi-Bold)| Normal | List item titles, modal headings, action labels. |
| `AppTypography.body` | 15sp | 1.50 | 400 (Regular) | Normal | Primary paragraph text, descriptions, form values. |
| `AppTypography.bodySmall`| 13sp | 1.45 | 400 (Regular) | Normal | Secondary subtitles, helper text, table rows. |
| `AppTypography.label` | 14sp | 1.25 | 600 (Semi-Bold)| Normal | Form input labels, button text, chip text. |
| `AppTypography.caption` | 12sp | 1.35 | 500 (Medium) | Normal | Badges, timestamps, small metadata tags. |

---

## 5. Spacing, Radii & Shadow Tokens

### 5.1. Spacing Grid (`AppSpacing`)
```dart
static const double xxs = 4;
static const double xs = 8;
static const double sm = 12;
static const double md = 16;
static const double lg = 20;
static const double xl = 24;
static const double xxl = 32;
static const double xxxl = 40;
static const double page = 20;     // Standard horizontal page padding
static const double section = 28;  // Vertical spacing between distinct sections
static const double minTouchTarget = 48; // Minimum accessible touch target
```

### 5.2. Corner Radii (`AppRadius`)
```dart
static const double xs = 6;     // Small badges, tags, chips
static const double sm = 10;    // Text fields, secondary buttons
static const double md = 14;    // Standard cards, action buttons
static const double lg = 18;    // Hero cards, dialog containers
static const double xl = 24;    // Bottom sheets, major containers
static const double pill = 999; // Pill-shaped status badges, FABs
```

### 5.3. Elevation & Shadows (`AppShadows`)
- **`AppShadows.card`:** `BoxShadow(color: Color(0x0F0D263F), blurRadius: 18, offset: Offset(0, 5))` — Soft, diffused elevation for resting cards.
- **`AppShadows.raised`:** `BoxShadow(color: Color(0x1A0D263F), blurRadius: 24, offset: Offset(0, 9))` — Elevated shadow for floating action buttons and modal surfaces.

---

## 6. Core Component Guidelines

### 6.1. Buttons
- **Primary Filled Button:** Uses `AppColors.primary` with pure white text, 48dp height, and `AppRadius.md`.
- **Secondary Outlined Button:** Uses `AppColors.border` with `AppColors.primary` text and `AppRadius.md`.
- **Destructive Button:** Uses `AppColors.error` background with white text for critical actions (e.g. user suspension, logout).

### 6.2. Status Badges (`StatusBadge`)
- Renders status pills combining `AppRadius.pill`, `AppTypography.caption`, an icon, and paired soft-background/hard-foreground colors (e.g., green on soft-green for "Resolved").

### 6.3. Step-by-Step Milestone Timelines (`RequestTimelineView`)
- Visual vertical connector lines joining circular status nodes.
- Completed steps display a checkmark with `AppColors.primary`; pending steps display a muted ring.

### 6.4. Location Card & Map Pin (`UploadLocationCard` & `DevelopmentMap`)
- Displays coordinates, reverse-geocoded address, accuracy indicator pill, and interactive pin placement.

---

## 7. Stitch Design Integration Protocol

When visual design artifacts (Figma exports, Stitch project screens, or asset bundles) are imported into this workspace:
1. **Token Synchronization:** Update `lib/core/theme/app_tokens.dart` first to mirror newly provided brand color codes, typography scales, or border radius specifications.
2. **Component Alignment:** Adjust shared atomic widgets in `lib/core/widgets/` to reflect new button styles, badge layouts, or card shadows.
3. **Screen Verification:** Inspect screens at standardized mobile viewport dimensions (360x800dp, 390x844dp, 412x915dp) ensuring safe area compliance and non-overflowing scroll views.
