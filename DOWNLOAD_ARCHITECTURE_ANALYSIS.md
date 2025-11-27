# MediaDojo Download Architecture Analysis

**Date**: 2025-01-23
**Status**: In Discussion - Not Yet Implemented
**Purpose**: Document architectural exploration for podcast episode downloads

---

## Table of Contents

1. [Current Architecture](#current-architecture)
2. [Proposed Architectures Explored](#proposed-architectures-explored)
3. [Key Technical Findings](#key-technical-findings)
4. [Recommended Architecture](#recommended-architecture)
5. [Implementation Considerations](#implementation-considerations)
6. [Open Questions](#open-questions)

---

## Current Architecture

### Overview

Downloads are managed centrally by `DownloadManager` (extends `ChangeNotifier`):

```dart
class DownloadManager extends ChangeNotifier {
  final _episodeToProgress = <EpisodeMedia, double?>{};
  final _episodeToCancelToken = <EpisodeMedia, CancelToken?>{};

  Future<String?> startOrCancelDownload(DownloadCapsule capsule);
  double? getProgress(EpisodeMedia? episode);
  Future<void> cancelAllDownloads();
}
```

### Data Flow

1. User clicks download button in UI
2. UI creates `DownloadCapsule` with episode + download directory
3. Calls `DownloadManager.startOrCancelDownload(capsule)`
4. DownloadManager uses Dio to download file
5. Progress tracked in `_episodeToProgress` map
6. On completion, persists to SharedPreferences via `PodcastLibraryService`
7. UI watches DownloadManager via watch_it

### Current Strengths

- ✅ Simple, proven pattern
- ✅ Single source of truth
- ✅ Works with episode immutability
- ✅ Compatible with compute() for episode parsing
- ✅ Easy to find all active downloads (single map)
- ✅ Easy to cancel all downloads

### Current Limitations

- Uses ChangeNotifier instead of command_it pattern
- Progress tracked in Maps (not Commands)
- Episodes are value objects, download state is external

---

## Proposed Architectures Explored

### Architecture 1: Commands on Episode Objects (REJECTED)

**Concept**: Each episode owns its download command

```dart
class EpisodeMedia {
  late final Command<void, String?> downloadCommand;

  EpisodeMedia(...) {
    downloadCommand = Command.createAsyncNoParam(() async {
      // Download logic
    });
  }
}
```

**Fatal Problems Identified**:

1. **Episode Recreation**: Episodes recreated on cache invalidation → commands lost
2. **copyWithX**: Creates new episodes → duplicate commands
3. **Isolate Incompatibility**: Episodes created in compute() → can't access di<>
4. **Shared Resources**: Every command needs Dio, PodcastLibraryService
5. **Global Operations**: Finding all downloads requires iterating all episodes
6. **Memory Overhead**: N commands for N episodes (most never downloaded)

**Verdict**: Architecturally unsound for immutable value objects.

---

### Architecture 2: Hybrid - Commands Call Central Service (REJECTED)

**Concept**: Episodes have commands that delegate to DownloadManager

```dart
class EpisodeMedia {
  late final Command<void, String?> downloadCommand;

  EpisodeMedia(...) {
    downloadCommand = Command.createAsyncNoParam(() async {
      final manager = di<DownloadManager>();
      return await manager.downloadEpisode(this);
    });
  }
}
```

**Problems Identified**:

1. **Command Progress**: Commands don't support incremental progress updates
   - Dio's `onReceiveProgress` fires repeatedly during download
   - Command.value only set at completion
   - Still need DownloadManager map for progress tracking

2. **Isolate Issue Remains**: Episodes created in compute() isolate
   - Can't access di<DownloadManager>() in isolate
   - Must remove compute() → blocks UI during feed parsing

3. **copyWithX Still Breaks**: Creates new command instances

4. **Still Need All Maps**: Progress map, cancel token map, registry
   - DownloadManager remains same complexity
   - Episodes now also complex

**Verdict**: Adds complexity without solving actual problems.

---

### Architecture 3: Episode-Owned Progress with Self-Registration (EXPLORING)

**Concept**: Episodes have ValueNotifier for progress, register with central registry

```dart
class EpisodeMedia {
  late final ValueNotifier<double?> downloadProgress;
  late final Command<void, String?> downloadCommand;

  EpisodeMedia(...) {
    downloadProgress = ValueNotifier<double?>(null);

    downloadCommand = Command.createAsyncNoParam(() async {
      final service = di<DownloadService>();
      di<DownloadRegistry>().register(this);

      try {
        return await service.downloadFile(
          url: this.url,
          onProgress: (progress) {
            downloadProgress.value = progress;
          },
        );
      } finally {
        di<DownloadRegistry>().unregister(this);
      }
    });
  }
}
```

**User Preferences**:
- Self-registration with central registry
- MapNotifier or ListNotifier for registry
- DownloadService provides basic download functions
- Check persistence at episode creation time

**Issues Remain**:
- Still can't initialize in compute() isolate
- copyWithX creates new instances with new state
- ValueNotifier is mutable state in value object

---

### Architecture 4: Immutable Episodes + MapNotifier Registry (CURRENT RECOMMENDATION)

**Concept**: Keep episodes immutable, add reactive registry

```dart
// Central registry with MapNotifier
class DownloadRegistry {
  final activeDownloads = MapNotifier<String, DownloadProgress>({});

  void register(EpisodeMedia episode, CancelToken token) {
    activeDownloads[episode.id] = DownloadProgress(episode, 0.0, token);
  }

  void updateProgress(String episodeId, double progress) {
    final existing = activeDownloads[episodeId];
    activeDownloads[episodeId] = existing.copyWith(progress: progress);
  }

  void unregister(String episodeId) {
    activeDownloads.remove(episodeId);
  }
}

// DownloadManager orchestrates
class DownloadManager {
  final DownloadRegistry _registry;

  Future<String?> startDownload(EpisodeMedia episode) async {
    final token = CancelToken();
    _registry.register(episode, token);

    try {
      await _dio.download(
        episode.url,
        path,
        onReceiveProgress: (received, total) {
          _registry.updateProgress(episode.id, received / total);
        },
        cancelToken: token,
      );

      _registry.unregister(episode.id);
      return path;
    } catch (e) {
      _registry.unregister(episode.id);
      rethrow;
    }
  }
}

// Episodes created with persistence check
extension PodcastX on Podcast {
  List<EpisodeMedia> toEpisodeMediaListWithPersistence(...) {
    return episodes.map((e) {
      var episode = EpisodeMedia(...);

      // Check if already downloaded
      final localPath = downloadService.getSavedPath(episode.url);
      if (localPath != null) {
        episode = episode.copyWithX(resource: localPath);
      }

      return episode;
    }).toList();
  }
}

// UI watches MapNotifier
final activeDownloads = watchValue((DownloadRegistry r) => r.activeDownloads);
```

**Benefits**:
- ✅ Episodes remain immutable
- ✅ Persistence checked at creation (after compute() returns)
- ✅ MapNotifier provides reactive updates
- ✅ Self-registration pattern (in manager, not episode)
- ✅ Compatible with compute() isolation
- ✅ copyWithX works correctly
- ✅ No media_kit contract violations
- ✅ O(1) lookup by episode ID

---

## Key Technical Findings

### Episode Creation Lifecycle

**Location**: `lib/podcasts/podcast_service.dart`

```dart
// Line 172: Runs in compute() isolate
final Podcast? podcast = await compute(loadPodcast, url);

// Line 180: Back on main thread - CAN access di<>
final episodes = podcast?.toEpisodeMediaList(url, item);
```

**Critical Finding**: Persistence CAN be checked at line 180 after compute() returns.

---

### Episode Caching Behavior

**Location**: `lib/podcasts/podcast_service.dart`

```dart
final Map<String, List<EpisodeMedia>> _episodeCache = {};

Future<List<EpisodeMedia>> findEpisodes({bool loadFromCache = true}) async {
  if (_episodeCache.containsKey(url) && loadFromCache) {
    return _episodeCache[url]!;  // Returns SAME instances
  }

  // Create new instances
  final episodes = podcast?.toEpisodeMediaList(url, item);
  _episodeCache[url] = episodes;
  return episodes;
}
```

**Critical Finding**: Episodes ARE cached and reused. Only recreated when:
- First fetch
- Cache invalidation (`loadFromCache: false`)
- Update checks find new content

---

### copyWithX Usage

**Only Used For**: Swapping streaming URL → local file path at playback time

**Locations**:
- `lib/podcasts/view/podcast_card.dart:111`
- `lib/podcasts/view/recent_downloads_button.dart:111`

```dart
final download = di<DownloadManager>().getDownload(e.id);
if (download != null) {
  return e.copyWithX(resource: download);  // Swap URL for playback
}
```

**Critical Finding**: copyWithX is NOT a bug - it's the correct pattern for media_kit.

---

### Media Kit Integration

**EpisodeMedia Hierarchy**:
```
Media (media_kit - immutable)
  ↑
UniqueMedia (app - adds ID-based equality)
  ↑
EpisodeMedia (app - podcast-specific data)
```

**Media.resource**: Final field that is the playable URL/path
- Immutable by design in media_kit
- Player.open() expects immutable Media instances
- Mutating would violate media_kit contract

**Critical Finding**: Making episodes mutable violates media_kit's assumptions.

---

### Command Pattern Limitations

**Command Execution Model**:
```dart
1. isRunning = true
2. Execute async function
3. Get result
4. value = result  ← Only set ONCE at end
5. isRunning = false
```

**No incremental updates during step 2!**

**Dio Download Model**:
```dart
await dio.download(
  url,
  path,
  onReceiveProgress: (count, total) {
    // Called MANY times during download
    // How to update Command.value? Can't!
  },
);
```

**Critical Finding**: Commands don't support progress tracking for long operations.

---

### Episode Equality & Hashing

**Implementation**: `lib/player/data/unique_media.dart`

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is UniqueMedia && other.id == id;
}

@override
int get hashCode => id.hashCode;
```

**ID Source**: `episode.guid` (globally unique identifier from podcast feed)

**Critical Finding**: Equality based on ID, NOT resource. Changing resource doesn't affect map lookups.

---

### MapNotifier vs ListNotifier

**From listen_it package** (already available):

**MapNotifier<K, V>**:
- O(1) lookup by key
- Implements ValueListenable<Map<K, V>>
- Automatic notifications on add/remove/update
- Can watch entire map or individual keys

**ListNotifier<T>**:
- O(n) search to find item
- Implements ValueListenable<List<T>>
- Automatic notifications on add/remove/update
- Can watch entire list or individual indices

**For Downloads**: MapNotifier is superior (keyed by episode ID)

---

## Recommended Architecture

### Core Principles

1. **Episodes remain immutable value objects**
   - No mutable state (commands, ValueNotifiers)
   - Can be used as Map keys safely
   - Compatible with media_kit's assumptions

2. **DownloadRegistry tracks active downloads**
   - MapNotifier<String, DownloadProgress>
   - Episodes self-register via DownloadManager
   - Unregister on completion or error

3. **Persistence checked at creation**
   - After compute() returns (can access di<>)
   - Episodes created with correct resource immediately

4. **DownloadManager orchestrates operations**
   - Handles Dio, cancellation, progress
   - Updates DownloadRegistry
   - Persists to PodcastLibraryService

### Component Responsibilities

**EpisodeMedia**: Immutable data
- Podcast episode metadata
- Playback resource (URL or local path)
- No download logic or state

**DownloadRegistry**: Reactive state tracking
- MapNotifier of active downloads
- Progress updates
- CancelToken management

**DownloadManager**: Download orchestration
- Executes downloads via Dio
- Updates DownloadRegistry
- Handles persistence
- Provides public API

**PodcastLibraryService**: Persistence layer
- SharedPreferences storage
- Download path queries
- Feed-to-downloads mapping

### Data Flow

```
1. User clicks download
   ↓
2. DownloadManager.startDownload(episode)
   ↓
3. Create CancelToken
   ↓
4. DownloadRegistry.register(episode, token)
   ↓
5. Dio.download() with onReceiveProgress
   ↓
6. DownloadRegistry.updateProgress() on each chunk
   ↓
7. On success: PodcastLibraryService.addDownload()
   ↓
8. DownloadRegistry.unregister(episode.id)
   ↓
9. UI watches MapNotifier, rebuilds automatically
```

---

## Implementation Considerations

### Files to Modify

1. **Create**: `lib/podcasts/download_registry.dart`
   - New class with MapNotifier
   - Registration/unregistration methods
   - Progress updates

2. **Modify**: `lib/podcasts/download_manager.dart`
   - Inject DownloadRegistry
   - Update methods to use registry
   - Remove ChangeNotifier (maybe - TBD)

3. **Modify**: `lib/extensions/podcast_x.dart`
   - Add persistence check to toEpisodeMediaList
   - Access DownloadService for saved paths

4. **Modify**: `lib/register_dependencies.dart`
   - Register DownloadRegistry singleton

5. **Modify**: UI files
   - Watch MapNotifier instead of ChangeNotifier
   - Simplified reactive updates

### Backward Compatibility

**Breaking Changes**:
- DownloadManager API changes
- UI watching different notifier

**Non-Breaking**:
- EpisodeMedia remains unchanged
- Persistence layer unchanged
- Dio integration unchanged

### Testing Strategy

**Unit Tests**:
- DownloadRegistry registration/unregistration
- Progress update logic
- Episode creation with persistence check

**Integration Tests**:
- Complete download flow
- Cancel during download
- Recent downloads dialog
- App restart persistence

---

## Open Questions

### 1. DownloadManager vs DownloadService Naming

**Current**: `DownloadManager` (extends ChangeNotifier)

**Proposed**: Rename to `DownloadService`?
- Provides download capability
- Doesn't "manage" UI state directly (DownloadRegistry does)
- Follows naming convention (PodcastService, RadioService)

**Decision**: TBD

### 2. Keep ChangeNotifier or Remove?

**Current**: DownloadManager extends ChangeNotifier for UI updates

**With Registry**: DownloadRegistry has MapNotifier
- Do we still need ChangeNotifier in manager?
- Or just have manager be a plain service class?

**Decision**: TBD

### 3. Command Integration

Should DownloadManager expose a download command?

```dart
class DownloadManager {
  late final Command<EpisodeMedia, String?> downloadCommand;
}
```

**Pros**: Aligns with command_it pattern
**Cons**: Command doesn't help with progress tracking

**Decision**: TBD

### 4. Progress Granularity

**Current**: double? (0.0 to 1.0) representing percentage

**Alternative**: More structured data?

```dart
class DownloadProgress {
  final int bytesReceived;
  final int bytesTotal;
  final double percentage;
  final EpisodeMedia episode;
  final CancelToken cancelToken;
}
```

**Decision**: Structured data (implemented in recommendation)

### 5. Error Handling

How should errors be surfaced?

**Current**: Message stream broadcasts error strings

**Options**:
- Keep message stream
- Add errors to DownloadProgress
- Separate error registry
- Command.error ValueListenable

**Decision**: TBD

---

## Finalized Architectural Decisions

### **Decision 1: DownloadManager → DownloadService**
**Rationale**: After moving state to DownloadRegistry and orchestration to PodcastManager, this class becomes a pure service providing download operations. UI will call PodcastManager, not DownloadService directly.

**Status**: ✅ DECIDED

### **Decision 2: Remove ChangeNotifier from DownloadService**
**Rationale**: MapNotifier in DownloadRegistry handles all reactive updates. DownloadService doesn't need its own notification mechanism.

**Status**: ✅ DECIDED

### **Decision 3: Add Download Command to PodcastManager**
**Rationale**: Aligns with command_it pattern. PodcastManager orchestrates download operations via command.

**Implementation**:
```dart
class PodcastManager {
  late final Command<EpisodeMedia, String?> downloadCommand;

  downloadCommand = Command.createAsync(
    (episode) => _downloadService.download(episode),
  );
}
```

**Status**: ✅ DECIDED

### **Decision 4: Error Handling via DownloadProgress**
**Approach**: Store error message in DownloadProgress object with auto-cleanup after delay.

**Implementation**:
```dart
class DownloadProgress {
  final EpisodeMedia episode;
  final double progress;
  final CancelToken cancelToken;
  final String? errorMessage;  // null if no error

  bool get hasError => errorMessage != null;
}
```

**Status**: ✅ DECIDED

### **Decision 5: Move Episode Cache to PodcastManager**
**Problem Identified**: Episode cache is currently in PodcastService but commands that use it are in PodcastManager. This violates separation of concerns.

**Solution**: Move `_episodeCache` from PodcastService to PodcastManager.

**Before**:
```dart
// PodcastService - has cache (wrong!)
class PodcastService {
  final Map<String, List<EpisodeMedia>> _episodeCache = {};
  Future<List<EpisodeMedia>> findEpisodes({...}) {
    if (_episodeCache.containsKey(url)) return _episodeCache[url]!;
    // ...
  }
}
```

**After**:
```dart
// PodcastService - stateless, pure operations
class PodcastService {
  Future<SearchResult> search({...});
  Future<Podcast> loadPodcastFeed(String url);
}

// PodcastManager - stateful, manages cache + registry
class PodcastManager {
  final PodcastService _service;
  final Map<String, List<EpisodeMedia>> _episodeCache = {};
  final DownloadRegistry downloads = DownloadRegistry();

  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
  late Command<EpisodeMedia, String?> downloadCommand;
}
```

**Rationale**:
- Services should be stateless (operations only)
- Managers should manage state (cache, registry)
- Logical grouping: cache and commands that use it live together
- Consistent pattern across the app

**Status**: ✅ DECIDED

### **Decision 6: DownloadRegistry Lives in PodcastManager**
**Rationale**: Downloads are part of the podcast domain. PodcastManager already manages episode cache, adding download registry is natural extension.

**Implementation**:
```dart
class PodcastManager {
  // Episode state
  final _episodeCache = <String, List<EpisodeMedia>>{};

  // Download state
  final downloads = DownloadRegistry();

  // Commands for both
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
  late Command<EpisodeMedia, String?> downloadCommand;
}
```

**Status**: ✅ DECIDED

### **Decision 7: Simplify Episode Creation - Remove Extension Method**
**Problem Identified**: Episode creation uses extension method with chained where/map, spread across files. Overly complicated.

**Current (Complicated)**:
```dart
// lib/extensions/podcast_x.dart
extension PodcastX on Podcast {
  List<EpisodeMedia> toEpisodeMediaList(String url, Item? item) => episodes
      .where((e) => e.contentUrl != null)
      .map((e) => EpisodeMedia(...))
      .toList();
}

// Called from PodcastService
final episodes = podcast?.toEpisodeMediaList(url, item) ?? <EpisodeMedia>[];
```

**After (Clean)**:
```dart
// Inline in PodcastManager._fetchEpisodes()
final episodes = podcastData.episodes
    .where((e) => e.contentUrl != null)
    .map((e) {
      // Check for download
      final localPath = di<PodcastLibraryService>().getDownload(e.guid);

      return EpisodeMedia(
        localPath ?? e.contentUrl!,  // Use local path if available
        episode: e,
        feedUrl: url,
        albumArtUrl: podcast.artworkUrl600 ?? podcast.artworkUrl ?? podcastData.image,
        collectionName: podcastData.title,
        artist: podcastData.copyright,
        genres: [if (podcast.primaryGenreName != null) podcast.primaryGenreName!],
      );
    })
    .toList();
```

**Benefits**:
- Functional style (idiomatic Dart) without over-engineering
- No extension method - all logic in one place
- Download persistence check integrated naturally
- More readable and maintainable

**Actions**:
- Delete `lib/extensions/podcast_x.dart`
- Move episode creation into PodcastManager
- Integrate download check inline

**Status**: ✅ DECIDED

---

## Next Steps

1. ✅ Document current knowledge (this file)
2. ✅ Iterate on architecture decisions (COMPLETE)
3. ✅ Finalize naming conventions (COMPLETE)
4. ✅ Decide on ChangeNotifier vs pure service (COMPLETE - removed)
5. ✅ Decide on Command integration (COMPLETE - added)
6. ✅ Finalize error handling approach (COMPLETE)
7. ✅ Decide cache location (COMPLETE - moved to Manager)
8. ⏳ Create detailed implementation plan
9. ⏳ Implement changes
10. ⏳ Test thoroughly
11. ⏳ Update documentation

---

## References

### Related Files

- `lib/podcasts/download_manager.dart` - Current implementation
- `lib/podcasts/podcast_library_service.dart` - Persistence layer
- `lib/podcasts/podcast_service.dart` - Episode creation
- `lib/extensions/podcast_x.dart` - toEpisodeMediaList extension
- `lib/player/data/episode_media.dart` - EpisodeMedia class
- `lib/player/data/unique_media.dart` - Equality implementation
- `lib/podcasts/view/download_button.dart` - UI integration
- `lib/podcasts/view/recent_downloads_button.dart` - Active downloads dialog

### Key Dependencies

- `dio` - HTTP downloads with progress
- `listen_it` - MapNotifier, ValueListenable operators
- `command_it` - Command pattern (if used)
- `watch_it` - Reactive UI watching
- `get_it` - Dependency injection
- `media_kit` - Media playback (requires immutable Media)

---

## Architectural Principles

### Separation of Concerns

- **Data**: EpisodeMedia (immutable)
- **State**: DownloadRegistry (reactive)
- **Behavior**: DownloadManager (orchestration)
- **Persistence**: PodcastLibraryService (storage)
- **UI**: Widgets (reactive watching)

### Immutability

- Value objects should be immutable
- State changes via object replacement, not mutation
- Aligns with Flutter's rebuild model
- Safe for use as Map keys

### Reactivity

- Use ValueListenables for state
- UI watches with watch_it
- Automatic updates, no manual subscriptions
- MapNotifier for O(1) keyed access

### Dependency Injection

- get_it for service locator
- Constructor injection where possible
- di<> only in main isolate
- Testability via mocking

---

**Document Status**: Living document - will be updated as architecture evolves.
