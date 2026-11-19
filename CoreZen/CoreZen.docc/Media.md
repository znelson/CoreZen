# Media

Play media files with mpv, and read their details and render their frames with FFmpeg.

## Overview

A ``ZENMediaPlayer`` plays a file with [mpv](https://mpv.io), and shows its video in a ``ZENMediaPlayerView``. A ``ZENMediaPlayerControlsView`` adds buttons to play, pause, step and skip, and a ``ZENMediaPlayerCTIView`` adds a timeline.

A ``ZENMediaFile`` reads a file's duration, frame size and codecs with [FFmpeg](https://ffmpeg.org), and a ``ZENFrameRenderer`` renders its frames as images, for thumbnails.

### Play a File

```objc
ZENMediaPlayer *player = [ZENMediaPlayer new];
[playerView attachPlayer:player];
[player loadFileURL:fileURL];
[player startPlayback];
```

The file loads paused, and `startPlayback` lets it play once it has loaded. To learn when the file is ready, or why it couldn't play, observe the player's ``ZENMediaPlayer/status`` with key-value observing. Its properties change only on the main thread.

### Render Thumbnails

```objc
ZENMediaFile *file = [ZENMediaFile mediaFileWithURL:fileURL];
ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:file];
[renderer renderFrames:10 width:320 height:180 completion:^(NSArray<ZENRenderedFrame *> *frames) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Show each frame's image, from the start of the file to its end
    });
}];
```

Making a media file reads from disk, so for a file that may be slow to reach, make it on a background queue. Terminate the media file once you're done with it, which also stops any renders still waiting.

### Quit Cleanly

Before the app quits, call ``ZENMediaPlayer/terminateAllPlayers`` and ``ZENMediaFile/terminateAllMediaFiles``, so that every player shuts its mpv instance down, and every media file closes its file.

## Topics

### Playback

- ``ZENMediaPlayer``

### Player Views

- ``ZENMediaPlayerView``
- ``ZENMediaPlayerControlsView``
- ``ZENMediaPlayerCTIView``

### Files and Frames

- ``ZENMediaFile``
- ``ZENFrameRenderer``
- ``ZENRenderedFrame``
- ``ZENRenderFrameResultsBlock``
- ``ZENRenderFramesResultsBlock``
