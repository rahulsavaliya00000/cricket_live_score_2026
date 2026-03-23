# FontAwesome Icons Migration Guide

## 1. Import FontAwesome in any file that uses icons:

```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
```

## 2. Common Icon Replacements:

| Material Icon | FontAwesome Icon | Usage |
|---|---|---|
| Icons.refresh_rounded | FontAwesomeIcons.rotate | Refresh/Reload action |
| Icons.sports_cricket | FontAwesomeIcons.cricketBat | Cricket/Sport indicator |
| Icons.arrow_back_rounded | FontAwesomeIcons.arrowLeft | Back navigation |
| Icons.check_circle_rounded | FontAwesomeIcons.solidCircleCheck | Success/Verified state |
| Icons.settings_outlined | FontAwesomeIcons.gear | Settings navigation |
| Icons.send_rounded | FontAwesomeIcons.paperPlane | Send/Submit action |
| Icons.chevron_right_rounded | FontAwesomeIcons.chevronRight | Forward navigation |
| Icons.stars_rounded | FontAwesomeIcons.solidStar | Premium/Rewards |
| Icons.info_outline | FontAwesomeIcons.circleInfo | Information/Details |
| Icons.redeem_rounded | FontAwesomeIcons.gift | Rewards/Redeem |
| Icons.arrow_forward_ios_rounded | FontAwesomeIcons.arrowRight | Forward navigation |
| Icons.download_rounded | FontAwesomeIcons.download | Download action |
| Icons.play_circle_outline | FontAwesomeIcons.circlePlay | Play action |
| Icons.manage_search | FontAwesomeIcons.magnifyingGlass | Search action |
| Icons.bug_report | FontAwesomeIcons.bug | Debug/Report issue |

## 3. Example Replacement:

### Before (Material Icons):
```dart
import 'package:flutter/material.dart';

Icon(Icons.refresh_rounded, size: 18)
```

### After (FontAwesome):
```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

FaIcon(FontAwesomeIcons.rotate, size: 18)
```

## 4. Color Usage:
FontAwesome icons use the same color properties as Material icons:
```dart
FaIcon(
  FontAwesomeIcons.cricketBat,
  size: 24,
  color: AppColors.primaryGreen,  // Respects theme colors
)
```

## 5. Files to Update:
- `lib/core/widgets/empty_state.dart` (Icons.refresh_rounded)
- `lib/core/widgets/error_view.dart` (Icons.refresh_rounded)
- `lib/core/widgets/team_flag.dart` (Icons.sports_cricket)
- `lib/features/profile/presentation/pages/terms_page.dart` (Icons.arrow_back_rounded)
- `lib/features/profile/presentation/pages/profile_page.dart` (Multiple icons)
- `lib/features/profile/presentation/pages/privacy_policy_page.dart` (Icons.arrow_back_rounded)
- `lib/features/profile/presentation/pages/suggestion_page.dart` (Icons.check_circle_rounded, Icons.send_rounded)
- `lib/features/wallet/presentation/widgets/spinning_fab.dart` (Icons.sports_cricket)
- `lib/features/profile/presentation/pages/ad_debug_page.dart` (Multiple icons)
- `lib/features/wallet/presentation/pages/spin_wheel_page.dart` (Icons.stars_rounded)
- `lib/features/profile/presentation/pages/premium_page.dart` (Icons.info_outline)
- `lib/features/wallet/presentation/pages/wallet_page.dart` (Multiple icons)

## 6. Navigation Icons (BottomNavigationBar/Navigation):
For bottom navigation, find the navigation widget and replace like:

### Before:
```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.home),
  label: 'Home',
)
```

### After:
```dart
BottomNavigationBarItem(
  icon: const FaIcon(FontAwesomeIcons.house),
  label: 'Home',
)
```

## 7. Solid vs Regular Icons:
- Use `FontAwesomeIcons.solidIconName` for filled/solid icons (e.g., solidCircleCheck, solidStar)
- Use `FontAwesomeIcons.iconName` for outline icons (e.g., circleInfo)

## 8. Find and Replace Pattern:
Search for: `Icon(Icons.` 
Replace with the appropriate `FaIcon(FontAwesomeIcons.` from the table above.

## 9. Verify After Changes:
- Run: `flutter pub get`
- Run: `flutter analyze` to check for errors
- Build and test: `flutter run`
