# Enterprise Kit — Flutter Enterprise App

> **0 to 100.** Every widget, theme, utility, route, and pattern — in one production-ready Flutter app.

---

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, riverpod, injectable, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Run development flavor
flutter run --target lib/main.dart
# or
flutter run --target lib/main.dart  # production
```

**Multi-flavor entry points:**
| Flavor | Entry point | 
|---|---|
| `production` | `lib/main.dart` → `void main()` |
| `development` | `lib/main.dart` → `void mainDev()` |
| `staging` | `lib/main.dart` → `void mainStaging()` |

---

## Architecture

```
lib/
├── main.dart                    # 3 entry points (prod / dev / staging)
├── app.dart                     # EnterpriseApp: MaterialApp.router + theme + debug overlay
│
├── core/
│   ├── bootstrap/               # App startup sequence (runZonedGuarded, SystemChrome, DI)
│   │   ├── app_bootstrap.dart   # AppBootstrap.run(flavor)
│   │   ├── app_flavor.dart      # AppFlavor enum
│   │   └── env_config.dart      # Per-flavor: baseUrl, wsUrl, flags
│   ├── debug/
│   │   ├── app_logger.dart      # Singleton logger (PrettyPrinter, env filter)
│   │   └── debug_overlay.dart   # Floating debug panel (dev only)
│   ├── di/
│   │   └── injection.dart       # GetIt + Injectable setup
│   ├── errors/
│   │   └── network_exception.dart # Typed network errors
│   ├── network/
│   │   ├── api_client.dart      # Dio client with full interceptor stack
│   │   └── interceptors/        # 7 interceptors: auth, retry, cache, connectivity, logging, error, metrics
│   ├── router/
│   │   ├── app_router.dart      # GoRouter with 16 routes
│   │   └── route_names.dart     # All route constants
│   ├── storage/
│   │   ├── secure_storage_service.dart  # flutter_secure_storage (AES/Keychain)
│   │   └── pref_storage_service.dart    # SharedPreferences wrapper
│   └── theme/
│       ├── app_theme.dart       # COMPLETE ThemeData — all 40+ component themes
│       ├── theme_provider.dart  # Riverpod: ThemeMode + Color providers
│       └── tokens/
│           ├── app_colors.dart     # ColorScheme + semantic colors + palette
│           ├── app_spacing.dart    # Spacing, radius, elevation, icon size tokens
│           ├── app_typography.dart # Google Fonts Inter, all 14 TextTheme styles
│           └── app_durations.dart  # Animation duration tokens
│
├── features/
│   ├── splash/                  # SplashPage with animated entry
│   ├── home/                    # HomePage — grid of all showcase sections
│   └── showcase/                # 16 showcase pages (one per component category)
│       ├── showcase_home_page.dart
│       ├── buttons_showcase_page.dart
│       ├── cards_showcase_page.dart
│       ├── dialogs_showcase_page.dart
│       ├── sheets_showcase_page.dart
│       ├── inputs_showcase_page.dart
│       ├── theme_showcase_page.dart
│       ├── images_showcase_page.dart
│       ├── typography_showcase_page.dart
│       ├── charts_showcase_page.dart
│       ├── network_showcase_page.dart
│       ├── utils_showcase_page.dart
│       ├── animations_showcase_page.dart
│       ├── loaders_showcase_page.dart
│       ├── pdf_showcase_page.dart
│       └── states_showcase_page.dart
│
├── l10n/
│   └── l10n.dart                # Localizations stub (en, ar, fr)
│
└── shared/
    ├── extensions/
    │   ├── string_extensions.dart     # 30+ String methods (validation, formatting, crypto)
    │   ├── datetime_extensions.dart   # 30+ DateTime helpers (isToday, timeAgo, startOfWeek…)
    │   ├── context_extensions.dart    # theme, mq, snackbar, navigation shortcuts
    │   ├── list_extensions.dart       # groupBy, chunked, distinct, sortedBy, partition…
    │   └── map_extensions.dart        # merge, filter, mapValues, inverted + NumExtensions
    ├── formatters/
    │   └── app_formatters.dart        # Currency, compact, date, phone, filesize, credit card…
    ├── helpers/
    │   └── app_helpers.dart           # UUID, clipboard, URL launcher, haptics, color utils…
    ├── mixins/
    │   └── app_mixins.dart            # LoggerMixin, LifecycleMixin, PaginationMixin, SearchMixin, FormMixin…
    ├── validators/
    │   └── form_validators.dart       # Composable validators: email, password, phone, URL, card…
    └── widgets/
        ├── buttons/
        │   └── app_button.dart        # 11 variants, 5 sizes, 7 factories, loading, icon, FAB
        ├── cards/
        │   └── app_card.dart          # 12 card types: basic, media, stat, list, profile, gradient…
        ├── dialogs/
        │   └── app_dialog.dart        # 10 dialog types: basic, confirm, danger, input, loading, success…
        ├── images/
        │   └── app_image.dart         # Network/asset/SVG/file/memory + AppAvatar, full-screen viewer
        ├── inputs/
        │   └── app_text_field.dart    # Full FormField + factories: email, password, phone, search, multiline, number
        ├── loaders/
        │   └── app_shimmer.dart       # Shimmer wrappers + pre-built: list, card, media, stat, grid
        ├── pdf/
        │   └── app_pdf_viewer.dart    # Syncfusion PDF viewer: network/asset/memory + toolbar + full-screen
        ├── sheets/
        │   └── app_sheet.dart         # 6 sheet types: standard, scrollable/draggable, full-screen, dialog, action, confirm
        ├── states/
        │   └── app_state_widget.dart  # 7 states: loading, empty, error, noConnection, noResults, comingSoon, accessDenied
        ├── texts/
        │   └── app_text.dart          # All 15 TextTheme variants + rich/linked text factories
        └── wrappers/
            └── app_wrapper.dart       # SafeArea, Padding, Visible, Conditional, Badge, Scaffold, Expansion wrappers
```

---

## Component Library

### AppButton — 11 variants
| Variant | Usage |
|---|---|
| `filled` | Primary actions |
| `outlined` | Secondary actions |
| `tonal` | Soft actions (secondary container) |
| `elevated` | Raised surface buttons |
| `text` | Inline / tertiary |
| `destructive` | Delete / dangerous actions |
| `ghost` | Subtle hover-only |
| `link` | Inline hyperlinks |
| `icon` | Icon-only buttons |
| `fab` | Floating action buttons |
| `extendedFab` | FAB with label |

### AppCard — 12 types
`basic` · `elevated` · `outlined` · `filled` · `media` · `stat` · `list` · `profile` · `gradient` · `action` · `banner` · `horizontal`

### AppDialog — 10 types
`show` · `confirm` · `danger` · `input` · `loading` · `success` · `error` · `warning` · `custom` · `fullScreen`

### AppSheet — 6 types
`show` · `scrollable` · `fullScreen` · `dialog` · `actions` · `confirm`

### AppTextField — 6 factories
`email` · `password` · `phone` · `search` · `multiline` · `number`

### AppStateWidget — 7 states
`loading` · `empty` · `error` · `noConnection` · `noResults` · `comingSoon` · `accessDenied`

---

## Theme System

`AppTheme.light` / `AppTheme.dark` cover **every** ThemeData parameter:

- All 30+ ColorScheme color slots
- 40+ component themes (appBar, card, buttons, inputs, dialogs, sheets, chips, tabs, nav, drawer, lists, checkboxes, switches, sliders, progress, badges, banners, datePicker, timePicker, divider, scrollbar, dataTable, segmentedButton, searchBar, popupMenu, menuBar, and more)
- WidgetStateProperty for all interactive states (pressed, hovered, focused, disabled, selected)
- InkSparkle splash factory
- Platform-specific PageTransitionsTheme
- `AppTheme.fromColor(Color, {bool dark})` — custom color builder

---

## Dependency Stack

```yaml
# State Management
flutter_riverpod: ^2.5.1       # Providers, StateNotifier
hooks_riverpod: ^2.5.1         # useRef, useState hooks

# Navigation
go_router: ^14.2.7             # Declarative routing with nested routes

# Networking
dio: ^5.6.0                    # HTTP client with interceptors
connectivity_plus: ^6.1.0      # Network connectivity

# Storage
flutter_secure_storage: ^9.2.2 # Keychain / AES encrypted storage
shared_preferences: ^2.3.2     # Light preferences
hive_flutter: ^1.1.0           # Local NoSQL cache

# UI
google_fonts: ^6.2.1           # Inter font family
flutter_svg: ^2.0.10+1         # SVG rendering
cached_network_image: ^3.4.1   # Network image with cache
flutter_animate: ^4.5.0        # Declarative animations
shimmer: ^3.0.0                # Skeleton loading
modal_bottom_sheet: ^3.0.0     # Enhanced bottom sheets
fl_chart: ^0.69.0              # Line / Bar / Pie charts
syncfusion_flutter_pdfviewer   # Full-featured PDF viewer

# Utilities
intl: ^0.19.0                  # Date/number formatting
uuid: ^4.5.1                   # UUID generation
url_launcher: ^6.3.1           # URL/email/phone launching
share_plus: ^10.0.3            # Native share sheet
logger: ^2.4.0                 # Structured logging
crypto: ^3.0.3                 # MD5/SHA256
```
