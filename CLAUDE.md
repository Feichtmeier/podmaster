# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MediaDojo is a desktop podcast and radio player built with Flutter. It serves as an **example application** to showcase the flutter_it ecosystem (`get_it`, `watch_it`, `command_it`, `listen_it`) for building well-structured Flutter applications without code generation.

The app targets Linux and macOS desktop platforms and demonstrates clean architecture with separation between UI, business logic (Managers), and data access (Services).

## Common Development Commands

### Building and Running

```bash
# Run the app (Linux/macOS)
flutter run

# Build for Linux
flutter build linux -v

# Build for macOS
flutter build macos -v
```

### Code Quality

```bash
# Analyze code (strict mode with fatal infos)
flutter analyze --fatal-infos

# Format code (REQUIRED before commits per user preferences)
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .

# Get dependencies
flutter pub get
```

### Testing

Note: Tests are currently commented out in CI. When adding tests:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart
```

### Flutter Version Management

This project uses FVM (Flutter Version Manager):

```bash
# Current Flutter version: 3.35.5 (see .fvmrc)
fvm use 3.35.5
fvm flutter run
fvm flutter build linux
```

## Architecture

MediaDojo follows a **three-layer architecture**:

```
UI (Flutter Widgets) ← watch/call → Managers (Business Logic) → Services (Data Access) → Data Sources
```

### Layer Responsibilities

**1. UI Layer** (`lib/*/view/`)
- Flutter widgets that display data and handle user interactions
- Uses `watch_it` to reactively watch Manager state
- Calls Commands on Managers (never directly calls Services)
- Must extend `WatchingWidget` or `WatchingStatefulWidget` when using watch_it functions

**2. Manager Layer** (`lib/*/*_manager.dart`)
- Contains business logic encapsulated in `Command` objects from `command_it`
- Registered as singletons in `get_it` (lives for entire app lifetime)
- Exposes Commands that UI can call and watch
- Orchestrates calls to Services
- No direct database/network access

**3. Service Layer** (`lib/*/*_service.dart`)
- Pure data access and business operations
- No UI dependencies
- Handles network requests, local storage, file I/O
- Can be pure Dart classes or use Flutter dependencies (e.g., `ChangeNotifier`)

### Key Managers

All registered in `lib/register_dependencies.dart`:

- **PodcastManager**: Podcast search and episode fetching via Commands
- **PlayerManager**: Audio playback control (extends `BaseAudioHandler`)
- **DownloadManager**: Episode download orchestration (extends `ChangeNotifier`)
- **RadioManager**: Radio station management
- **SettingsManager**: User preferences
- **SearchManager**: Global search coordination
- **CollectionManager**: User's collection management

### Key Services

- **PodcastService**: Podcast search API integration (`podcast_search` package)
- **PodcastLibraryService**: Podcast subscriptions storage (`SharedPreferences`)
- **RadioService**: Radio station data fetching (`radio_browser_api`)
- **RadioLibraryService**: Radio favorites storage
- **SettingsService**: Persistent user settings
- **NotificationsService**: Local notifications
- **OnlineArtService**: Album art fetching

### Dependency Registration Pattern

See `lib/register_dependencies.dart` for the complete setup. Key patterns:

```dart
// Singleton with async initialization
di.registerSingletonAsync<ServiceName>(
  () async => ServiceName(),
  dependsOn: [OtherService],
);

// Lazy singleton (created on first access)
di.registerLazySingleton<ServiceName>(
  () => ServiceName(),
  dispose: (s) => s.dispose(),
);

// Singleton with dependencies
di.registerSingletonWithDependencies<Manager>(
  () => Manager(service: di<ServiceName>()),
  dependsOn: [ServiceName],
);
```

**IMPORTANT**: Use `di` (alias for `GetIt.instance`) throughout the codebase, not `GetIt.instance` directly.

## flutter_it Patterns

### Command Pattern

Commands wrap functions and provide reactive state. UI can call them and watch for results/errors separately:

```dart
// In Manager
late Command<String?, SearchResult> updateSearchCommand;

updateSearchCommand = Command.createAsync<String?, SearchResult>(
  (query) async => _podcastService.search(searchQuery: query),
  initialValue: SearchResult(items: []),
);

// In UI
di<PodcastManager>().updateSearchCommand.run('flutter');

// Watch results elsewhere
final results = watchValue((context) =>
  di<PodcastManager>().updateSearchCommand.value
);
```

### watch_it Requirements

**CRITICAL**: When using any watch_it functions (`watch`, `watchValue`, `callOnce`, `createOnce`, `registerHandler`):

- Widget MUST extend `WatchingWidget` or `WatchingStatefulWidget`
- All watch calls MUST be in the same order on every build
- Never conditionally call watch functions

### Manager Lifecycle

Managers are singletons that live for the entire app lifetime:
- No need to dispose Commands or subscriptions manually
- They're cleaned up when the app process terminates
- Document this clearly in Manager classes (see `PodcastManager` for example)

### ValueListenable Operations

Use `listen_it` operators for reactive transformations:

```dart
// Debounce search input
searchManager.textChangedCommand
  .debounce(const Duration(milliseconds: 500))
  .listen((filterText, sub) => updateSearchCommand.run(filterText));
```

## Code Style and Linting

The project uses strict linting rules (see `analysis_options.yaml`):

- **Single quotes** for strings
- **Const constructors** where possible
- **Trailing commas** required
- **Relative imports** within the project
- **No print statements** - use logging utilities
- **Cancel subscriptions** properly
- **Close sinks** when done

Key rules to follow:
- `prefer_single_quotes: true`
- `prefer_const_constructors: true`
- `require_trailing_commas: true`
- `prefer_relative_imports: true`
- `avoid_print: true`
- `cancel_subscriptions: true`

## Platform Considerations

### Desktop-Specific Setup

- **Window Management**: Uses `window_manager` package for window control
- **System Theme**: Uses `system_theme` for accent colors
- **Audio Backend**: Uses `media_kit` with MPV for audio/video playback
- **Linux Dependencies**: Requires libmpv-dev, libnotify-dev, libgtk-3-dev
- **Audio Service**: Integrates with desktop media controls via `audio_service`

### Platform Detection

Use `lib/common/platforms.dart` for platform checks:

```dart
if (Platforms.isLinux) { ... }
if (Platforms.isMacOS) { ... }
if (Platforms.isDesktop) { ... }
```

## Project Structure

```
lib/
├── app/                      # App initialization and main widget
│   ├── app.dart             # Root widget
│   ├── home.dart            # Main navigation scaffold
│   └── app_config.dart      # App constants
├── common/                   # Shared utilities and widgets
│   ├── view/                # Reusable UI components
│   ├── platforms.dart       # Platform detection
│   └── logging.dart         # Debug logging utilities
├── podcasts/                 # Podcast feature
│   ├── podcast_manager.dart
│   ├── podcast_service.dart
│   ├── podcast_library_service.dart
│   ├── download_manager.dart
│   ├── data/                # Podcast data models
│   └── view/                # Podcast UI widgets
├── radio/                    # Radio feature
│   ├── radio_manager.dart
│   ├── radio_service.dart
│   └── view/
├── player/                   # Audio player feature
│   ├── player_manager.dart
│   ├── data/                # Player state models
│   └── view/                # Player UI
├── settings/                 # Settings feature
│   ├── settings_manager.dart
│   ├── settings_service.dart
│   └── view/
├── search/                   # Global search
│   └── search_manager.dart
├── collection/               # User collections
│   └── collection_manager.dart
├── extensions/               # Dart extension methods
├── l10n/                     # Localization (generated)
└── register_dependencies.dart # Dependency injection setup
```

## Key Dependencies

- **flutter_it**: Umbrella package containing get_it, watch_it, command_it, listen_it
- **media_kit**: Audio/video playback engine
- **podcast_search**: Podcast search API client
- **radio_browser_api**: Radio station database API
- **audio_service**: OS media controls integration
- **shared_preferences**: Local key-value storage
- **dio**: HTTP client for downloads
- **window_manager**: Desktop window control
- **yaru**: Ubuntu-style widgets and theming

Several dependencies are pinned to specific git commits for stability.

## Data Models

### Media Types

The app uses a hierarchy of media types for playback:

- **UniqueMedia** (base class): Represents any playable media
- **EpisodeMedia**: Podcast episodes
- **StationMedia**: Radio stations
- **LocalMedia**: Local audio files

All found in `lib/player/data/`.

### Podcast Data

- **PodcastMetadata**: Extended podcast info with subscription state
- **Item**: From `podcast_search` package (podcast or episode)
- **Episode**: From `podcast_search` package

### Download Management

- **DownloadCapsule**: Encapsulates episode + download directory for download operations

## File Naming and Organization

- **Managers**: `{feature}_manager.dart` (e.g., `podcast_manager.dart`)
- **Services**: `{feature}_service.dart` (e.g., `podcast_service.dart`)
- **Views**: `lib/{feature}/view/{widget_name}.dart`
- **Data Models**: `lib/{feature}/data/{model_name}.dart`
- **Extensions**: `lib/extensions/{type}_x.dart` (e.g., `string_x.dart`)

## Development Workflow

1. **Before making changes**: Read existing code to understand patterns
2. **Run analyzer**: `flutter analyze --fatal-infos` to catch issues
3. **Format code**: `dart format .` before committing (REQUIRED per user rules)
4. **Test locally**: Run the app to verify changes
5. **Never commit without asking** (per user's global rules)

## CI/CD

GitHub Actions workflows (`.github/workflows/`):

- **ci.yaml**: Runs on PRs
  - Analyzes with `flutter analyze --fatal-infos`
  - Checks formatting with `dart format --set-exit-if-changed`
  - Builds Linux binary (requires Rust toolchain and system dependencies)
  - Tests are currently disabled

- **release.yml**: Handles release builds

## Important Notes

- **No code generation**: This project intentionally avoids build_runner and code gen
- **No tests currently**: Test infrastructure exists but tests are commented out
- **Desktop only**: No mobile support (Android/iOS specific code paths exist but are unused)
- **Global exception handling**: `Command.globalExceptionHandler` is set in `PodcastManager`
- **FVM required**: Use FVM to ensure correct Flutter version (3.35.5)

## Anti-Patterns to Avoid

- ❌ Don't call Services directly from UI - always go through Managers
- ❌ Don't use `GetIt.instance` directly - use `di` alias
- ❌ Don't forget to extend `WatchingWidget`/`WatchingStatefulWidget` when using watch_it
- ❌ Don't conditionally call watch_it functions
- ❌ Don't add watch_it functions in different orders across rebuilds
- ❌ Don't use `print()` - use `printMessageInDebugMode()` from `common/logging.dart`
- ❌ Don't commit without formatting code first
- ❌ Don't create new features without following the Manager → Service pattern
