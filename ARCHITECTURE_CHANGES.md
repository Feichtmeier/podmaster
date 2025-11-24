# Architecture Changes Overview

**Date**: 2025-01-24
**Status**: ✅ Implemented

---

## Summary

Refactored the podcast download system using **command_it 9.4.1** with per-episode download commands, progress tracking, and cancellation support. Improved separation of concerns and aligned with flutter_it patterns.

**Core Principle**: Commands own their execution state, Services are stateless, Managers orchestrate.

---

## Implementation Details

### 1. Download Commands (Per-Episode)

**What**: Each `EpisodeMedia` has its own `downloadCommand` with progress/cancellation

```dart
class EpisodeMedia {
  late final downloadCommand = _createDownloadCommand();

  bool get isDownloaded => downloadCommand.progress.value == 1.0;

  Command<void, void> _createDownloadCommand() {
    final command = Command.createAsyncNoParamNoResultWithProgress(
      (handle) async {
        // 1. Add to active downloads
        di<PodcastManager>().activeDownloads.add(this);

        // 2. Download with progress
        await di<DownloadService>().download(
          episode: this,
          cancelToken: cancelToken,
          onProgress: (received, total) {
            handle.updateProgress(received / total);
          },
        );

        // 3. Remove from active
        di<PodcastManager>().activeDownloads.remove(this);
      },
      errorFilter: const LocalAndGlobalErrorFilter(),
    )..errors.listen((error, subscription) {
        di<PodcastManager>().activeDownloads.remove(this);
      });

    // Initialize progress to 1.0 if already downloaded
    if (_wasDownloadedOnCreation) {
      command.resetProgress(progress: 1.0);
    }

    return command;
  }
}
```

**Benefits**:
- ✅ Commands own execution state (no separate registry needed)
- ✅ Built-in progress tracking via `command.progress`
- ✅ Built-in cancellation via `command.cancel()`
- ✅ UI watches command state directly

---

### 2. Active Downloads Tracking

**What**: `PodcastManager` tracks currently downloading episodes in a `ListNotifier`

```dart
class PodcastManager {
  final activeDownloads = ListNotifier<EpisodeMedia>();
}
```

**Why ListNotifier (not MapNotifier)**:
- No need for O(1) lookup - UI just iterates for display
- Simpler API: `add()`, `remove()`
- Episodes are reference-equal (same instances)

**Usage**:
```dart
// UI watches for display
watchValue((PodcastManager m) => m.activeDownloads)

// Command manages lifecycle
di<PodcastManager>().activeDownloads.add(this);    // Start
di<PodcastManager>().activeDownloads.remove(this); // End/Error
```

---

### 3. Renamed DownloadManager → DownloadService

**Change**: Removed all state tracking, made it stateless

**What was removed**:
- ❌ `extends ChangeNotifier`
- ❌ `_episodeToProgress` map
- ❌ `_episodeToCancelToken` map
- ❌ `messageStream` for error notifications
- ❌ `startOrCancelDownload()` method
- ❌ `isDownloaded()` method (moved to EpisodeMedia)

**What remains** (stateless operations):
- ✅ `download()` - Downloads episode with progress callback
- ✅ `getDownload()` - Gets local path for downloaded episode
- ✅ `deleteDownload()` - Deletes downloaded episode
- ✅ `feedsWithDownloads` - Lists feeds with downloads

---

### 4. Global Error Handling

**What**: Replaced messageStream with command_it's global error stream

```dart
// In home.dart
registerStreamHandler<Stream<CommandError>, CommandError>(
  target: Command.globalErrors,
  handler: (context, snapshot, cancel) {
    if (snapshot.hasData) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Download error: ${snapshot.data!.error}')),
      );
    }
  },
);
```

**Why**:
- Uses command_it v9.1.0+ global error stream
- `LocalAndGlobalErrorFilter` routes errors to both local handler and global stream
- Local handler cleans up (removes from activeDownloads)
- Global handler shows user notification

---

### 5. Automatic Downloaded Episode Handling

**What**: Episodes automatically use local path when downloaded

**Factory Constructor Pattern**:
```dart
factory EpisodeMedia(...) {
  // Call getDownload only once
  final downloadPath = di<DownloadService>().getDownload(episode.contentUrl);
  final wasDownloaded = downloadPath != null;
  final effectiveResource = downloadPath ?? resource;

  return EpisodeMedia._(
    effectiveResource,
    wasDownloaded: wasDownloaded,
    ...
  );
}
```

**Benefits**:
- ✅ Only one `getDownload()` call during construction
- ✅ Resource automatically set to local path if downloaded
- ✅ Progress initialized to 1.0 for downloaded episodes
- ✅ No need for `copyWithX()` in UI code

**isDownloaded Getter**:
```dart
bool get isDownloaded => downloadCommand.progress.value == 1.0;
```

---

### 6. UI Simplification

**Before**:
```dart
final isDownloaded = watchPropertyValue(
  (DownloadService m) => m.isDownloaded(episode.url),
);
if (isDownloaded) {
  final download = di<DownloadService>().getDownload(episode.url);
  episode.copyWithX(resource: download!);
}
```

**After**:
```dart
final progress = watch(episode.downloadCommand.progress).value;
final isDownloaded = progress == 1.0;

// Episode resource is already correct - just use it directly
di<PlayerManager>().setPlaylist([episode]);
```

---

## Architecture Pattern

```
┌─────────────────┐
│  EpisodeMedia   │ ← Owns downloadCommand with progress/cancellation
│  - downloadCommand
│  - isDownloaded
└─────────────────┘
        │
        ├──→ DownloadService (stateless operations)
        │
        └──→ PodcastManager.activeDownloads (tracks active)
```

**State Flow**:
1. User clicks download → `episode.downloadCommand.run()`
2. Command adds to `activeDownloads` → UI shows in list
3. Command calls `DownloadService.download()` with progress callback
4. Progress updates via `handle.updateProgress()` → UI shows indicator
5. On success: removes from `activeDownloads`, progress stays 1.0
6. On error: removes from `activeDownloads`, routes to global error stream

---

## Key Files Changed

### Core Changes
- **lib/player/data/episode_media.dart** - Added downloadCommand, factory constructor
- **lib/podcasts/podcast_manager.dart** - Added activeDownloads ListNotifier
- **lib/podcasts/download_service.dart** - Removed state, kept operations only
- **lib/app/home.dart** - Added Command.globalErrors handler

### UI Updates
- **lib/podcasts/view/download_button.dart** - Watch command progress/isRunning
- **lib/podcasts/view/recent_downloads_button.dart** - Watch activeDownloads
- **lib/podcasts/view/podcast_card.dart** - Simplified (no copyWithX)
- **lib/podcasts/view/podcast_page_episode_list.dart** - Use episode.isDownloaded

### Removed
- messageStream and downloadMessageStreamHandler (replaced by Command.globalErrors)
- DownloadService.isDownloaded() method (use episode.isDownloaded)
- All copyWithX() calls for setting local resource (automatic now)

---

## Dependencies

- **command_it**: ^9.4.1 (progress tracking, cancellation, global errors)
- **listen_it**: (ListNotifier for activeDownloads)
- **dio**: (CancelToken for download cancellation)

---

## Benefits

1. **Simpler State Management**: Commands own their state, no separate registry
2. **Better UI Integration**: Watch command properties directly
3. **Automatic Resource Handling**: Episodes "just work" with local paths
4. **Single Lookup**: Only call getDownload() once during construction
5. **Type Safety**: All command properties are ValueListenable<T>
6. **Cancellation**: Built-in cooperative cancellation support
7. **Error Handling**: Global error stream for user notifications
8. **Progress Tracking**: Real-time progress updates via handle.updateProgress()

---

## Migration Notes

**For Future Features**:
- To add download functionality to new media types, add downloadCommand to their class
- Use same pattern: command adds/removes from activeDownloads
- Set errorFilter to LocalAndGlobalErrorFilter for user notifications
- Initialize progress to 1.0 if already downloaded on creation
