//
//  MPVConstants.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

// audio-speed-correction
extern const char* kMPVProperty_AudioSpeedCorrection;
// video-speed-correction
extern const char* kMPVProperty_VideoSpeedCorrection;
// display-sync-active
extern const char* kMPVProperty_DisplaySyncActive;
// filename
extern const char* kMPVProperty_Filename;
// filename/no-ext
extern const char* kMPVProperty_FilenameNoExt;
// file-size
extern const char* kMPVProperty_FileSize;
// estimated-frame-count
extern const char* kMPVProperty_EstimatedFrameCount;
// estimated-frame-number
extern const char* kMPVProperty_EstimatedFrameNumber;
// pid
extern const char* kMPVProperty_PID;
// path
extern const char* kMPVProperty_Path;
// stream-open-filename
extern const char* kMPVProperty_StreamOpenFilename;
// media-title
extern const char* kMPVProperty_MediaTitle;
// file-format
extern const char* kMPVProperty_FileFormat;
// current-demuxer
extern const char* kMPVProperty_CurrentDemuxer;
// stream-path
extern const char* kMPVProperty_StreamPath;
// stream-pos
extern const char* kMPVProperty_StreamPos;
// stream-end
extern const char* kMPVProperty_StreamEnd;
// duration
extern const char* kMPVProperty_Duration;
// avsync
extern const char* kMPVProperty_AVSync;
// total-avsync-change
extern const char* kMPVProperty_TotalAVSyncChange;
// decoder-frame-drop-count
extern const char* kMPVProperty_DecoderFrameDropCount;
// frame-drop-count
extern const char* kMPVProperty_FrameDropCount;
// mistimed-frame-count
extern const char* kMPVProperty_MistimedFrameCount;
// vsync-ratio
extern const char* kMPVProperty_VSyncRatio;
// vo-delayed-frame-count
extern const char* kMPVProperty_VODelayedFrameCount;
// percent-pos
extern const char* kMPVProperty_PercentPos;
// time-pos
extern const char* kMPVProperty_TimePos;
// time-start
extern const char* kMPVProperty_TimeStart;
// time-remaining
extern const char* kMPVProperty_TimeRemaining;
// audio-pts
extern const char* kMPVProperty_AudioPts;
// playtime-remaining
extern const char* kMPVProperty_PlaytimeRemaining;
// playback-time
extern const char* kMPVProperty_PlaybackTime;
// chapter
extern const char* kMPVProperty_Chapter;
// edition
extern const char* kMPVProperty_Edition;
// current-edition
extern const char* kMPVProperty_CurrentEdition;
// chapters
extern const char* kMPVProperty_Chapters;
// editions
extern const char* kMPVProperty_Editions;
// edition-list
extern const char* kMPVProperty_EditionList;
// edition-list/count
extern const char* kMPVProperty_EditionListCount;
// edition-list/N/id
extern const char* kMPVProperty_EditionListID_N;
// edition-list/N/default
extern const char* kMPVProperty_EditionListDefault_N;
// edition-list/N/title
extern const char* kMPVProperty_EditionListTitle_N;
// metadata
extern const char* kMPVProperty_Metadata;
// metadata/list/count
extern const char* kMPVProperty_MetadataListCount;
// metadata/list/N/key
extern const char* kMPVProperty_MetadataListKey_N;
// metadata/list/N/value
extern const char* kMPVProperty_MetadataListValue_N;
// filtered-metadata
extern const char* kMPVProperty_FilteredMetadata;
// chapter-metadata
extern const char* kMPVProperty_ChapterMetadata;
// idle-active
extern const char* kMPVProperty_IdleActive;
// core-idle
extern const char* kMPVProperty_CoreIdle;
// cache-speed
extern const char* kMPVProperty_CacheSpeed;
// demuxer-cache-duration
extern const char* kMPVProperty_DemuxerCacheDuration;
// demuxer-cache-time
extern const char* kMPVProperty_DemuxerCacheTime;
// demuxer-cache-idle
extern const char* kMPVProperty_DemuxerCacheIdle;
// demuxer-cache-state
extern const char* kMPVProperty_DemuxerCacheState;
// demuxer-via-network
extern const char* kMPVProperty_DemuxerViaNetwork;
// demuxer-start-time
extern const char* kMPVProperty_DemuxerStartTime;
// paused-for-cache
extern const char* kMPVProperty_PausedForCache;
// cache-buffering-state
extern const char* kMPVProperty_CacheBufferingState;
// eof-reached
extern const char* kMPVProperty_EOFReached;
// seeking
extern const char* kMPVProperty_Seeking;
// mixer-active
extern const char* kMPVProperty_MixerActive;
// ao-volume
extern const char* kMPVProperty_AOVolume;
// ao-mute
extern const char* kMPVProperty_AOMute;
// audio-codec
extern const char* kMPVProperty_AudioCodec;
// audio-codec-name
extern const char* kMPVProperty_AudioCodecName;
// audio-params
extern const char* kMPVProperty_AudioParams;
// audio-params/format
extern const char* kMPVProperty_AudioParamsFormat;
// audio-params/samplerate
extern const char* kMPVProperty_AudioParamsSampleRate;
// audio-params/channels
extern const char* kMPVProperty_AudioParamsChannels;
// audio-params/hr-channels
extern const char* kMPVProperty_AudioParamsHRChannels;
// audio-params/channel-count
extern const char* kMPVProperty_AudioParamsChannelCount;
// audio-out-params
extern const char* kMPVProperty_AudioOutParams;
// colormatrix
extern const char* kMPVProperty_ColorMatrix;
// colormatrix-input-range
extern const char* kMPVProperty_ColorMatrixInputRange;
// colormatrix-primaries
extern const char* kMPVProperty_ColorMatrixPrimaries;
// hwdec
extern const char* kMPVProperty_Hwdec;
// hwdec-current
extern const char* kMPVProperty_HwdecCurrent;
// hwdec-interop
extern const char* kMPVProperty_HwdecInterop;
// video-format
extern const char* kMPVProperty_VideoFormat;
// video-codec
extern const char* kMPVProperty_VideoCodec;
// width
extern const char* kMPVProperty_Width;
// height
extern const char* kMPVProperty_Height;
// video-params
extern const char* kMPVProperty_VideoParams;
// video-params/pixelformat
extern const char* kMPVProperty_VideoParamsPixelFormat;
// video-params/hw-pixelformat
extern const char* kMPVProperty_VideoParamsHwPixelFormat;
// video-params/average-bpp
extern const char* kMPVProperty_VideoParamsAverageBPP;
// video-params/w
extern const char* kMPVProperty_VideoParamsW;
// video-params/h
extern const char* kMPVProperty_VideoParamsH;
// video-params/dw
extern const char* kMPVProperty_VideoParamsDW;
// video-params/dh
extern const char* kMPVProperty_VideoParamsDH;
// video-params/aspect
extern const char* kMPVProperty_VideoParamsAspect;
// video-params/par
extern const char* kMPVProperty_VideoParamsPAR;
// video-params/colormatrix
extern const char* kMPVProperty_VideoParamsColorMatrix;
// video-params/colorlevels
extern const char* kMPVProperty_VideoParamsColorLevels;
// video-params/primaries
extern const char* kMPVProperty_VideoParamsPrimaries;
// video-params/gamma
extern const char* kMPVProperty_VideoParamsGamma;
// video-params/sig-peak
extern const char* kMPVProperty_VideoParamsSigPeek;
// video-params/light
extern const char* kMPVProperty_VideoParamsLight;
// video-params/chroma-location
extern const char* kMPVProperty_VideoParamsChromaLocation;
// video-params/rotate
extern const char* kMPVProperty_VideoParamsRotate;
// video-params/stereo-in
extern const char* kMPVProperty_VideoParamsStereoIn;
// video-params/alpha
extern const char* kMPVProperty_VideoParamsAlpha;
// dwidth
extern const char* kMPVProperty_DWidth;
// dheight
extern const char* kMPVProperty_DHeight;
// video-dec-params
extern const char* kMPVProperty_VideoDecParams;
// video-out-params
extern const char* kMPVProperty_VideoOutParams;
// video-frame-info
extern const char* kMPVProperty_VideoFrameInfo;
// video-frame-info/picture-type
extern const char* kMPVProperty_VideoFrameInfoPictureType;
// video-frame-info/interlaced
extern const char* kMPVProperty_VideoFrameInfoInterlaced;
// video-frame-info/tff
extern const char* kMPVProperty_VideoFrameInfoTFF;
// video-frame-info/repeat
extern const char* kMPVProperty_VideoFrameInfoRepeat;
// container-fps
extern const char* kMPVProperty_ContainerFPS;
// estimated-vf-fps
extern const char* kMPVProperty_EstimatedVfFPS;
// window-scale
extern const char* kMPVProperty_WindowScale;
// current-window-scale
extern const char* kMPVProperty_CurrentWindowScale;
// focused
extern const char* kMPVProperty_Focused;
// display-names
extern const char* kMPVProperty_DisplayNames;
// display-fps
extern const char* kMPVProperty_DisplayFPS;
// estimated-display-fps
extern const char* kMPVProperty_EstimatedDisplayFPS;
// vsync-jitter
extern const char* kMPVProperty_VSyncJitter;
// display-width
extern const char* kMPVProperty_DisplayWidth;
// display-height
extern const char* kMPVProperty_DisplayHeight;
// display-hidpi-scale
extern const char* kMPVProperty_DisplayHiDPIScale;
// video-aspect
extern const char* kMPVProperty_VideoAspect;
// osd-width
extern const char* kMPVProperty_OSDWidth;
// osd-height
extern const char* kMPVProperty_OSDHeight;
// osd-par
extern const char* kMPVProperty_OSDPAR;
// osd-dimensions
extern const char* kMPVProperty_OSDDimensions;
// osd-dimensions/w
extern const char* kMPVProperty_OSDDimensionsW;
// osd-dimensions/h
extern const char* kMPVProperty_OSDDimensionsH;
// osd-dimensions/par
extern const char* kMPVProperty_OSDDimensionsPAR;
// osd-dimensions/aspect
extern const char* kMPVProperty_OSDDimensionsAspect;
// osd-dimensions/mt
extern const char* kMPVProperty_OSDDimensionsMT;
// osd-dimensions/mb
extern const char* kMPVProperty_OSDDimensionsMB;
// osd-dimensions/ml
extern const char* kMPVProperty_OSDDimensionsML;
// osd-dimensions/mr
extern const char* kMPVProperty_OSDDimensionsMR;
// mouse-pos
extern const char* kMPVProperty_MousePos;
// mouse-pos/x
extern const char* kMPVProperty_MousePosX;
// mouse-pos/y
extern const char* kMPVProperty_MousePosY;
// mouse-pos/hover
extern const char* kMPVProperty_MousePosHover;
// sub-text
extern const char* kMPVProperty_SubText;
// sub-text-ass
extern const char* kMPVProperty_SubTextAss;
// secondary-sub-text
extern const char* kMPVProperty_SecondarySubText;
// sub-start
extern const char* kMPVProperty_SubStart;
// secondary-sub-start
extern const char* kMPVProperty_SecondarySubStart;
// sub-end
extern const char* kMPVProperty_SubEnd;
// secondary-sub-end
extern const char* kMPVProperty_SecondarySubEnd;
// playlist-pos
extern const char* kMPVProperty_PlaylistPos;
// playlist-pos-1
extern const char* kMPVProperty_PlaylistPos1;
// playlist-current-pos
extern const char* kMPVProperty_PlaylistCurrentPos;
// playlist-playing-pos
extern const char* kMPVProperty_PlaylistPlayingPos;
// playlist-count
extern const char* kMPVProperty_PlaylistCount;
// playlist
extern const char* kMPVProperty_Playlist;
// playlistCount1
extern const char* kMPVProperty_PlaylistCount1;
// playlist/N/filename
extern const char* kMPVProperty_PlaylistFilename_N;
// playlist/N/playing
extern const char* kMPVProperty_PlaylistPlaying_N;
// playlist/N/current
extern const char* kMPVProperty_PlaylistCurrent_N;
// playlist/N/title
extern const char* kMPVProperty_PlaylistTitle_N;
// playlist/N/id
extern const char* kMPVProperty_PlaylistID_N;
// track-list
extern const char* kMPVProperty_TrackList;
// track-list/count
extern const char* kMPVProperty_TrackListCount;
// track-list/N/id
extern const char* kMPVProperty_TrackListID_N;
// track-list/N/type
extern const char* kMPVProperty_TrackListType_N;
// track-list/N/src-id
extern const char* kMPVProperty_TrackListSrcID_N;
// track-list/N/title
extern const char* kMPVProperty_TrackListTitle_N;
// track-list/N/lang
extern const char* kMPVProperty_TrackListLang_N;
// track-list/N/image
extern const char* kMPVProperty_TrackListImage_N;
// track-list/N/albumart
extern const char* kMPVProperty_TrackListAlbumArt_N;
// track-list/N/default
extern const char* kMPVProperty_TrackListDefault_N;
// track-list/N/forced
extern const char* kMPVProperty_TrackListForced_N;
// track-list/N/codec
extern const char* kMPVProperty_TrackListCodec_N;
// track-list/N/external
extern const char* kMPVProperty_TrackListExternal_N;
// track-list/N/external-filename
extern const char* kMPVProperty_TrackListExternalFilename_N;
// track-list/N/selected
extern const char* kMPVProperty_TrackListSelected_N;
// track-list/N/main-selection
extern const char* kMPVProperty_TrackListMainSelection_N;
// track-list/N/ff-index
extern const char* kMPVProperty_TrackListFFIndex_N;
// track-list/N/decoder-desc
extern const char* kMPVProperty_TrackListDecoderDesc_N;
// track-list/N/demux-w
extern const char* kMPVProperty_TrackListDemuxW_N;
// track-list/N/demux-h
extern const char* kMPVProperty_TrackListDemuxH_N;
// track-list/N/demux-channel-count
extern const char* kMPVProperty_TrackListDemuxChannelCount_N;
// track-list/N/demux-channels
extern const char* kMPVProperty_TrackListDemuxChannels_N;
// track-list/N/demux-samplerate
extern const char* kMPVProperty_TrackListDemuxSamplerate_N;
// track-list/N/demux-fps
extern const char* kMPVProperty_TrackListDemuxFPS_N;
// track-list/N/demux-bitrate
extern const char* kMPVProperty_TrackListDemuxBitrate_N;
// track-list/N/demux-rotation
extern const char* kMPVProperty_TrackListDemuxRotation_N;
// track-list/N/demux-par
extern const char* kMPVProperty_TrackListDemuxPAR_N;
// track-list/N/audio-channels
extern const char* kMPVProperty_TrackListAudioChannels_N;
// track-list/N/replaygain-track-peak
extern const char* kMPVProperty_TrackListReplaygainTrackPeak_N;
// track-list/N/replaygain-track-gain
extern const char* kMPVProperty_TrackListReplaygainTrackGain_N;
// track-list/N/replaygain-album-peak
extern const char* kMPVProperty_TrackListReplaygainAlbumPeak_N;
// track-list/N/replaygain-album-gain
extern const char* kMPVProperty_TrackListReplaygainAlbumGain_N;
// chapter-list
extern const char* kMPVProperty_ChapterList;
// chapter-list/count
extern const char* kMPVProperty_ChapterListCount;
// chapter-list/N/title
extern const char* kMPVProperty_ChapterListTitle_N;
// chapter-list/N/time
extern const char* kMPVProperty_ChapterListTime_N;
// af
extern const char* kMPVProperty_AF;
// vf
extern const char* kMPVProperty_VF;
// seekable
extern const char* kMPVProperty_Seekable;
// partially-seekable
extern const char* kMPVProperty_PartiallySeekable;
// playback-abort
extern const char* kMPVProperty_PlaybackAbort;
// cursor-autohide
extern const char* kMPVProperty_CursorAutohide;
// osd-sym-cc
extern const char* kMPVProperty_OSDSymCC;
// osd-ass-cc
extern const char* kMPVProperty_OSDAssCC;
// vo-configured
extern const char* kMPVProperty_VOConfigured;
// vo-passes
extern const char* kMPVProperty_VOPasses;
// vo-passes/TYPE/count
extern const char* kMPVProperty_VOPassesCount_TYPE;
// vo-passes/TYPE/N/desc
extern const char* kMPVProperty_VOPassesDesc_TYPE_N;
// vo-passes/TYPE/N/last
extern const char* kMPVProperty_VOPassesLast_TYPE_N;
// vo-passes/TYPE/N/avg
extern const char* kMPVProperty_VOPassesAvg_TYPE_N;
// vo-passes/TYPE/N/peak
extern const char* kMPVProperty_VOPassesPeak_TYPE_N;
// vo-passes/TYPE/N/count
extern const char* kMPVProperty_VOPassesCount_TYPE_N;
// vo-passes/TYPE/N/samples/M
extern const char* kMPVProperty_VOPassesSamples_TYPE_N_M;
// perf-info
extern const char* kMPVProperty_PerfInfo;
// video-bitrate
extern const char* kMPVProperty_VideoBitrate;
// audio-bitrate
extern const char* kMPVProperty_AudioBitrate;
// sub-bitrate
extern const char* kMPVProperty_SubBitrate;
// packet-video-bitrate
extern const char* kMPVProperty_PacketVideoBitrate;
// packet-audio-bitrate
extern const char* kMPVProperty_PacketAudioBitrate;
// packet-sub-bitrate
extern const char* kMPVProperty_PacketSubBitrate;
// audio-device-list
extern const char* kMPVProperty_AudioDeviceList;
// audio-device
extern const char* kMPVProperty_AudioDevice;
// current-vo
extern const char* kMPVProperty_CurrentVO;
// current-ao
extern const char* kMPVProperty_CurrentAO;
// shared-script-properties
extern const char* kMPVProperty_SharedScriptProperties;
// working-directory
extern const char* kMPVProperty_WorkingDirectory;
// protocol-list
extern const char* kMPVProperty_ProtocolList;
// decoder-list
extern const char* kMPVProperty_DecoderList;
// encoder-list
extern const char* kMPVProperty_EncoderList;
// demuxer-lavf-list
extern const char* kMPVProperty_DemuxerLavfList;
// input-key-list
extern const char* kMPVProperty_InputKeyList;
// mpv-version
extern const char* kMPVProperty_MPVVersion;
// mpv-configuration
extern const char* kMPVProperty_MPVConfiguration;
// ffmpeg-version
extern const char* kMPVProperty_ffmpegVersion;
// libass-version
extern const char* kMPVProperty_libassVersion;
// options/NAME
extern const char* kMPVProperty_Options_NAME;
// file-local-options/NAME
extern const char* kMPVProperty_FileLocalOptions_NAME;
// option-info/NAME
extern const char* kMPVProperty_OptionInfo_NAME;
// option-info/NAME/name
extern const char* kMPVProperty_OptionInfoName_NAME;
// option-info/NAME/type
extern const char* kMPVProperty_OptionInfoType_NAME;
// option-info/NAME/set-from-commandline
extern const char* kMPVProperty_OptionInfoSetFromCommandline_NAME;
// option-info/NAME/set-locally
extern const char* kMPVProperty_OptionInfoSetLocally_NAME;
// option-info/NAME/default-value
extern const char* kMPVProperty_OptionInfoDefaultValue_NAME;
// option-info/NAME/min
extern const char* kMPVProperty_OptionInfoMin_NAME;
// option-info/NAME/max
extern const char* kMPVProperty_OptionInfoMax_NAME;
// option-info/NAME/choices
extern const char* kMPVProperty_OptionInfoChoices_NAME;
// property-list
extern const char* kMPVProperty_PropertyList;
// profile-list
extern const char* kMPVProperty_ProfileList;
// command-list
extern const char* kMPVProperty_CommandList;
// input-bindings
extern const char* kMPVProperty_InputBindings;

// --alang=<languagecode[
extern const char* kMPVOption_TrackSelection_ALang;
// --slang=<languagecode[
extern const char* kMPVOption_TrackSelection_SLang;
// --vlang=<...>
extern const char* kMPVOption_TrackSelection_VLang;
// --aid=<ID|auto|no>
extern const char* kMPVOption_TrackSelection_AID;
// --sid=<ID|auto|no>
extern const char* kMPVOption_TrackSelection_SID;
// --vid=<ID|auto|no>
extern const char* kMPVOption_TrackSelection_VID;
// --edition=<ID|auto>
extern const char* kMPVOption_TrackSelection_Edition;
// --track-auto-selection=<yes|no>
extern const char* kMPVOption_TrackSelection_TrackAutoSelection;
// --subs-with-matching-audio=<yes|no>
extern const char* kMPVOption_TrackSelection_SubsWithMatchingAudio;

// --start=<relative time>
extern const char* kMPVOption_Playback_ControlStart;
// --end=<relative time>
extern const char* kMPVOption_Playback_ControlEnd;
// --length=<relative time>
extern const char* kMPVOption_Playback_ControlLength;
// --rebase-start-time=<yes|no>
extern const char* kMPVOption_Playback_ControlRebaseStartTime;
// --speed=<0.01-100>
extern const char* kMPVOption_Playback_ControlSpeed;
// --pause
extern const char* kMPVOption_Playback_ControlPause;
// --shuffle
extern const char* kMPVOption_Playback_ControlShuffle;
// --playlist-start=<auto|index>
extern const char* kMPVOption_Playback_ControlPlaylistStart;
// --playlist=<filename>
extern const char* kMPVOption_Playback_ControlPlaylist;
// --chapter-merge-threshold=<number>
extern const char* kMPVOption_Playback_ControlChapterMergeThreshold;
// --chapter-seek-threshold=<seconds>
extern const char* kMPVOption_Playback_ControlChapterSeekThreshold;
// --hr-seek=<no|absolute|yes|default>
extern const char* kMPVOption_Playback_ControlHRSeek;
// --hr-seek-demuxer-offset=<seconds>
extern const char* kMPVOption_Playback_ControlHRSeekDemuxerOffset;
// --hr-seek-framedrop=<yes|no>
extern const char* kMPVOption_Playback_ControlHRSeekFramedrop;
// --index=<mode>
extern const char* kMPVOption_Playback_ControlIndex;
// --load-unsafe-playlists
extern const char* kMPVOption_Playback_ControlLoadUnsafePlaylists;
// --access-references=<yes|no>
extern const char* kMPVOption_Playback_ControlAccessReferences;
// --loop-playlist=<N|inf|force|no>
extern const char* kMPVOption_Playback_ControlLoopPlaylist;
// --loop-file=<N|inf|no>
extern const char* kMPVOption_Playback_ControlLoopFile;
// --loop=<N|inf|no>
extern const char* kMPVOption_Playback_ControlLoop;
// --ab-loop-a=<time>
extern const char* kMPVOption_Playback_ControlABLoopA;
// --ab-loop-b=<time>
extern const char* kMPVOption_Playback_ControlABLoopB;
// --ab-loop-count=<N|inf>
extern const char* kMPVOption_Playback_ControlABLoopCount;
// --ordered-chapters
extern const char* kMPVOption_Playback_ControlOrderedChapters;
// --no-ordered-chapters
extern const char* kMPVOption_Playback_ControlNoOrderedChapters;
// --ordered-chapters-files=<playlist-file>
extern const char* kMPVOption_Playback_ControlOrderedChaptersFiles;
// --chapters-file=<filename>
extern const char* kMPVOption_Playback_ControlChaptersFile;
// --sstep=<sec>
extern const char* kMPVOption_Playback_ControlSstep;
// --stop-playback-on-init-failure=<yes|no>
extern const char* kMPVOption_Playback_ControlStopPlaybackOnInitFailure;
// --play-dir=<forward|+|backward|->
extern const char* kMPVOption_Playback_ControlPlayDir;
// --video-reversal-buffer=<bytesize>
extern const char* kMPVOption_Playback_ControlVideoReversalBuffer;
// --audio-reversal-buffer=<bytesize>
extern const char* kMPVOption_Playback_ControlAudioReversalBuffer;
// --video-backward-overlap=<auto|number>
extern const char* kMPVOption_Playback_ControlVideoBackwardOverlap;
// --audio-backward-overlap=<auto|number>
extern const char* kMPVOption_Playback_ControlAudioBackwardOverlap;
// --video-backward-batch=<number>
extern const char* kMPVOption_Playback_ControlVideoBackwardBatch;
// --audio-backward-batch=<number>
extern const char* kMPVOption_Playback_ControlAudioBackwardBatch;
// --demuxer-backward-playback-step=<seconds>
extern const char* kMPVOption_Playback_ControlDemuxerBackwardPlaybackStep;

// --help
extern const char* kMPVOption_ProgramBehavior_Help;
// --h
extern const char* kMPVOption_ProgramBehavior_H;
// --version
extern const char* kMPVOption_ProgramBehavior_Version;
// --no-config
extern const char* kMPVOption_ProgramBehavior_NoConfig;
// --list-options
extern const char* kMPVOption_ProgramBehavior_ListOptions;
// --list-properties
extern const char* kMPVOption_ProgramBehavior_ListProperties;
// --list-protocols
extern const char* kMPVOption_ProgramBehavior_ListProtocols;
// --log-file=<path>
extern const char* kMPVOption_ProgramBehavior_LogFile;
// --config-dir=<path>
extern const char* kMPVOption_ProgramBehavior_ConfigDir;
// --save-position-on-quit
extern const char* kMPVOption_ProgramBehavior_SavePositionOnQuit;
// --watch-later-directory=<path>
extern const char* kMPVOption_ProgramBehavior_WatchLaterDirectory;
// --dump-stats=<filename>
extern const char* kMPVOption_ProgramBehavior_DumpStats;
// --idle=<no|yes|once>
extern const char* kMPVOption_ProgramBehavior_Idle;
// --include=<configuration-file>
extern const char* kMPVOption_ProgramBehavior_Include;
// --load-scripts=<yes|no>
extern const char* kMPVOption_ProgramBehavior_LoadScripts;
// --script=<filename>
extern const char* kMPVOption_ProgramBehavior_Script;
// --scripts=file1.lua:file2.lua:...
extern const char* kMPVOption_ProgramBehavior_Scripts;
// --script-opts=key1=value1
extern const char* kMPVOption_ProgramBehavior_ScriptOpts;
// --merge-files
extern const char* kMPVOption_ProgramBehavior_MergeFiles;
// --no-resume-playback
extern const char* kMPVOption_ProgramBehavior_NoResumePlayback;
// --resume-playback-check-mtime
extern const char* kMPVOption_ProgramBehavior_ResumePlaybackCheckMtime;
// --profile=<profile1
extern const char* kMPVOption_ProgramBehavior_Profile;
// --reset-on-next-file=<all|option1
extern const char* kMPVOption_ProgramBehavior_ResetOnNextFile;
// --watch-later-options=option1
extern const char* kMPVOption_ProgramBehavior_WatchLaterOptions;
// --write-filename-in-watch-later-config
extern const char* kMPVOption_ProgramBehavior_WriteFilenameInWatchLaterConfig;
// --ignore-path-in-watch-later-config
extern const char* kMPVOption_ProgramBehavior_IgnorePathInWatchLaterConfig;
// --show-profile=<profile>
extern const char* kMPVOption_ProgramBehavior_ShowProfile;
// --use-filedir-conf
extern const char* kMPVOption_ProgramBehavior_UseFiledirConf;
// --ytdl
extern const char* kMPVOption_ProgramBehavior_Ytdl;
// --no-ytdl
extern const char* kMPVOption_ProgramBehavior_NoYtdl;
// --ytdl-format=<ytdl|best|worst|mp4|webm|...>
extern const char* kMPVOption_ProgramBehavior_YtdlFormat;
// --ytdl-raw-options=<key>=<value>[
extern const char* kMPVOption_ProgramBehavior_YtdlRawOptions;
// --load-stats-overlay=<yes|no>
extern const char* kMPVOption_ProgramBehavior_LoadStatsOverlay;
// --load-osd-console=<yes|no>
extern const char* kMPVOption_ProgramBehavior_LoadOSDConsole;
// --load-auto-profiles=<yes|no|auto>
extern const char* kMPVOption_ProgramBehavior_LoadAutoProfiles;
// --player-operation-mode=<cplayer|pseudo-gui>
extern const char* kMPVOption_ProgramBehavior_PlayerOperationMode;

// --vo=<driver>
extern const char* kMPVOption_Video_VO;
// --vd=<...>
extern const char* kMPVOption_Video_VD;
// --vf=<filter1[=parameter1:parameter2:...]
extern const char* kMPVOption_Video_VF;
// --untimed
extern const char* kMPVOption_Video_Untimed;
// --framedrop=<mode>
extern const char* kMPVOption_Video_Framedrop;
// --video-latency-hacks=<yes|no>
extern const char* kMPVOption_Video_VideoLatencyHacks;
// --override-display-fps=<fps>
extern const char* kMPVOption_Video_OverrideDisplayFPS;
// --display-fps=<fps>
extern const char* kMPVOption_Video_DisplayFPS;
// --hwdec=<api>
extern const char* kMPVOption_Video_Hwdec;
// --gpu-hwdec-interop=<auto|all|no|name>
extern const char* kMPVOption_Video_GPUHwdecInterop;
// --hwdec-extra-frames=<N>
extern const char* kMPVOption_Video_HwdecExtraFrames;
// --hwdec-image-format=<name>
extern const char* kMPVOption_Video_HwdecImageFormat;
// --cuda-decode-device=<auto|0..>
extern const char* kMPVOption_Video_CudaDecodeDevice;
// --vaapi-device=<device file>
extern const char* kMPVOption_Video_VaapiDevice;
// --panscan=<0.0-1.0>
extern const char* kMPVOption_Video_Panscan;
// --video-aspect-override=<ratio|no>
extern const char* kMPVOption_Video_VideoAspectOverride;
// --video-aspect-method=<bitstream|container>
extern const char* kMPVOption_Video_VideoAspectMethod;
// --video-unscaled=<no|yes|downscale-big>
extern const char* kMPVOption_Video_VideoUnscaled;
// --video-pan-x=<value>
extern const char* kMPVOption_Video_VideoPanX;
// --video-pan-y=<value>
extern const char* kMPVOption_Video_VideoPanY;
// --video-rotate=<0-359|no>
extern const char* kMPVOption_Video_VideoRotate;
// --video-zoom=<value>
extern const char* kMPVOption_Video_VideoZoom;
// --video-scale-x=<value>
extern const char* kMPVOption_Video_VideoScaleX;
// --video-scale-y=<value>
extern const char* kMPVOption_Video_VideoScaleY;
// --video-align-x=<-1-1>
extern const char* kMPVOption_Video_VideoAlignX;
// --video-align-y=<-1-1>
extern const char* kMPVOption_Video_VideoAlignY;
// --video-margin-ratio-left=<val>
extern const char* kMPVOption_Video_VideoMarginRatioLeft;
// --video-margin-ratio-right=<val>
extern const char* kMPVOption_Video_VideoMarginRatioRight;
// --video-margin-ratio-top=<val>
extern const char* kMPVOption_Video_VideoMarginRatioTop;
// --video-margin-ratio-bottom=<val>
extern const char* kMPVOption_Video_VideoMarginRatioBottom;
// --correct-pts
extern const char* kMPVOption_Video_CorrectPts;
// --no-correct-pts
extern const char* kMPVOption_Video_NoCorrectPts;
// --fps=<float>
extern const char* kMPVOption_Video_FPS;
// --deinterlace=<yes|no>
extern const char* kMPVOption_Video_Deinterlace;
// --frames=<number>
extern const char* kMPVOption_Video_Frames;
// --video-output-levels=<outputlevels>
extern const char* kMPVOption_Video_VideoOutputLevels;
// --hwdec-codecs=<codec1
extern const char* kMPVOption_Video_HwdecCodecs;
// --vd-lavc-check-hw-profile=<yes|no>
extern const char* kMPVOption_Video_VDLavcCheckHwProfile;
// --vd-lavc-software-fallback=<yes|no|N>
extern const char* kMPVOption_Video_VDLavcSoftwareFallback;
// --vd-lavc-dr=<yes|no>
extern const char* kMPVOption_Video_VDLavcDr;
// --vd-lavc-bitexact
extern const char* kMPVOption_Video_VDLavcBitexact;
// --vd-lavc-fast
extern const char* kMPVOption_Video_VDLavcFast;
// --vd-lavc-o=<key>=<value>
extern const char* kMPVOption_Video_VDLavcO;
// --vd-lavc-show-all=<yes|no>
extern const char* kMPVOption_Video_VDLavcShowAll;
// --vd-lavc-skiploopfilter=<skipvalue> (H.264 only)
extern const char* kMPVOption_Video_VDLavcSkiploopfilter;
// --vd-lavc-skipidct=<skipvalue> (MPEG-1/2 only)
extern const char* kMPVOption_Video_VDLavcSkipidct;
// --vd-lavc-skipframe=<skipvalue>
extern const char* kMPVOption_Video_VDLavcSkipframe;
// --vd-lavc-framedrop=<skipvalue>
extern const char* kMPVOption_Video_VDLavcFramedrop;
// --vd-lavc-threads=<N>
extern const char* kMPVOption_Video_VDLavcThreads;
// --vd-lavc-assume-old-x264=<yes|no>
extern const char* kMPVOption_Video_VDLavcAssumeOldX264;
// --swapchain-depth=<N>
extern const char* kMPVOption_Video_SwapchainDepth;

// --audio-pitch-correction=<yes|no>
extern const char* kMPVOption_Audio_AudioPitchCorrection;
// --audio-device=<name>
extern const char* kMPVOption_Audio_AudioDevice;
// --audio-exclusive=<yes|no>
extern const char* kMPVOption_Audio_AudioExclusive;
// --audio-fallback-to-null=<yes|no>
extern const char* kMPVOption_Audio_AudioFallbackToNull;
// --ao=<driver>
extern const char* kMPVOption_Audio_AO;
// --af=<filter1[=parameter1:parameter2:...]
extern const char* kMPVOption_Audio_AF;
// --audio-spdif=<codecs>
extern const char* kMPVOption_Audio_AudioSpdif;
// --ad=<decoder>
extern const char* kMPVOption_Audio_AD;
// --volume=<value>
extern const char* kMPVOption_Audio_Volume;
// --replaygain=<no|track|album>
extern const char* kMPVOption_Audio_Replaygain;
// --replaygain-preamp=<db>
extern const char* kMPVOption_Audio_ReplaygainPreamp;
// --replaygain-clip=<yes|no>
extern const char* kMPVOption_Audio_ReplaygainClip;
// --replaygain-fallback=<db>
extern const char* kMPVOption_Audio_ReplaygainFallback;
// --audio-delay=<sec>
extern const char* kMPVOption_Audio_AudioDelay;
// --mute=<yes|no|auto>
extern const char* kMPVOption_Audio_Mute;
// --softvol=<no|yes|auto>
extern const char* kMPVOption_Audio_Softvol;
// --audio-demuxer=<[+]name>
extern const char* kMPVOption_Audio_AudioDemuxer;
// --ad-lavc-ac3drc=<level>
extern const char* kMPVOption_Audio_ADLavcAC3DRC;
// --ad-lavc-downmix=<yes|no>
extern const char* kMPVOption_Audio_ADLavcDownmix;
// --ad-lavc-threads=<0-16>
extern const char* kMPVOption_Audio_ADLavcThreads;
// --ad-lavc-o=<key>=<value>
extern const char* kMPVOption_Audio_ADLavcO;
// --ad-spdif-dtshd=<yes|no>
extern const char* kMPVOption_Audio_ADSpdifDTSHD;
// --dtshd
extern const char* kMPVOption_Audio_DTSHD;
// --no-dtshd
extern const char* kMPVOption_Audio_NoDTSHD;
// --audio-channels=<auto-safe|auto|layouts>
extern const char* kMPVOption_Audio_AudioChannels;
// --audio-display=<no|embedded-first|external-first>
extern const char* kMPVOption_Audio_AudioDisplay;
// --audio-files=<files>
extern const char* kMPVOption_Audio_AudioFiles;
// --audio-file=<file>
extern const char* kMPVOption_Audio_AudioFile;
// --audio-format=<format>
extern const char* kMPVOption_Audio_AudioFormat;
// --audio-samplerate=<Hz>
extern const char* kMPVOption_Audio_AudioSamplerate;
// --gapless-audio=<no|yes|weak>
extern const char* kMPVOption_Audio_GaplessAudio;
// --initial-audio-sync
extern const char* kMPVOption_Audio_InitialAudioSync;
// --no-initial-audio-sync
extern const char* kMPVOption_Audio_NoInitialAudioSync;
// --volume-max=<100.0-1000.0>
extern const char* kMPVOption_Audio_VolumeMax;
// --softvol-max=<...>
extern const char* kMPVOption_Audio_SoftvolMax;
// --audio-file-auto=<no|exact|fuzzy|all>
extern const char* kMPVOption_Audio_AudioFileAuto;
// --no-audio-file-auto
extern const char* kMPVOption_Audio_NoAudioFileAuto;
// --audio-file-paths=<path1:path2:...>
extern const char* kMPVOption_Audio_AudioFilePaths;
// --audio-client-name=<name>
extern const char* kMPVOption_Audio_AudioClientName;
// --audio-buffer=<seconds>
extern const char* kMPVOption_Audio_AudioBuffer;
// --audio-stream-silence=<yes|no>
extern const char* kMPVOption_Audio_AudioStreamSilence;
// --audio-wait-open=<secs>
extern const char* kMPVOption_Audio_AudioWaitOpen;

// --sub-demuxer=<[+]name>
extern const char* kMPVOption_Subtitles_SubDemuxer;
// --sub-delay=<sec>
extern const char* kMPVOption_Subtitles_SubDelay;
// --sub-files=<file-list>
extern const char* kMPVOption_Subtitles_SubFiles;
// --sub-file=<filename>
extern const char* kMPVOption_Subtitles_SubFile;
// --secondary-sid=<ID|auto|no>
extern const char* kMPVOption_Subtitles_SecondarySid;
// --sub-scale=<0-100>
extern const char* kMPVOption_Subtitles_SubScale;
// --sub-scale-by-window=<yes|no>
extern const char* kMPVOption_Subtitles_SubScaleByWindow;
// --sub-scale-with-window=<yes|no>
extern const char* kMPVOption_Subtitles_SubScaleWithWindow;
// --sub-ass-scale-with-window=<yes|no>
extern const char* kMPVOption_Subtitles_SubAssScaleWithWindow;
// --embeddedfonts=<yes|no>
extern const char* kMPVOption_Subtitles_Embeddedfonts;
// --sub-pos=<0-150>
extern const char* kMPVOption_Subtitles_SubPos;
// --sub-speed=<0.1-10.0>
extern const char* kMPVOption_Subtitles_SubSpeed;
// --sub-ass-force-style=<[Style.]Param=Value
extern const char* kMPVOption_Subtitles_SubAssForceStyle;
// --sub-ass-hinting=<none|light|normal|native>
extern const char* kMPVOption_Subtitles_SubAssHinting;
// --sub-ass-line-spacing=<value>
extern const char* kMPVOption_Subtitles_SubAssLineSpacing;
// --sub-ass-shaper=<simple|complex>
extern const char* kMPVOption_Subtitles_SubAssShaper;
// --sub-ass-styles=<filename>
extern const char* kMPVOption_Subtitles_SubAssStyles;
// --sub-ass-override=<yes|no|force|scale|strip>
extern const char* kMPVOption_Subtitles_SubAssOverride;
// --sub-ass-force-margins
extern const char* kMPVOption_Subtitles_SubAssForceMargins;
// --sub-use-margins
extern const char* kMPVOption_Subtitles_SubUseMargins;
// --sub-ass-vsfilter-aspect-compat=<yes|no>
extern const char* kMPVOption_Subtitles_SubAssVsfilterAspectCompat;
// --sub-ass-vsfilter-blur-compat=<yes|no>
extern const char* kMPVOption_Subtitles_SubAssVsfilterBlurCompat;
// --sub-ass-vsfilter-color-compat=<basic|full|force-601|no>
extern const char* kMPVOption_Subtitles_SubAssVsfilterColorCompat;
// --stretch-dvd-subs=<yes|no>
extern const char* kMPVOption_Subtitles_StretchDVDSubs;
// --stretch-image-subs-to-screen=<yes|no>
extern const char* kMPVOption_Subtitles_StretchImageSubsToScreen;
// --image-subs-video-resolution=<yes|no>
extern const char* kMPVOption_Subtitles_ImageSubsVideoResolution;
// --sub-ass
extern const char* kMPVOption_Subtitles_SubAss;
// --no-sub-ass
extern const char* kMPVOption_Subtitles_NoSubAss;
// --sub-auto=<no|exact|fuzzy|all>
extern const char* kMPVOption_Subtitles_SubAuto;
// --no-sub-auto
extern const char* kMPVOption_Subtitles_NoSubAuto;
// --sub-codepage=<codepage>
extern const char* kMPVOption_Subtitles_SubCodepage;
// --sub-fix-timing=<yes|no>
extern const char* kMPVOption_Subtitles_SubFixTiming;
// --sub-forced-only=<auto|yes|no>
extern const char* kMPVOption_Subtitles_SubForcedOnly;
// --sub-fps=<rate>
extern const char* kMPVOption_Subtitles_SubFps;
// --sub-gauss=<0.0-3.0>
extern const char* kMPVOption_Subtitles_SubGauss;
// --sub-gray
extern const char* kMPVOption_Subtitles_SubGray;
// --sub-paths=<path1:path2:...>
extern const char* kMPVOption_Subtitles_SubPaths;
// --sub-file-paths=<path-list>
extern const char* kMPVOption_Subtitles_SubFilePaths;
// --sub-visibility
extern const char* kMPVOption_Subtitles_SubVisibility;
// --no-sub-visibility
extern const char* kMPVOption_Subtitles_NoSubVisibility;
// --secondary-sub-visibility
extern const char* kMPVOption_Subtitles_SecondarySubVisibility;
// --no-secondary-sub-visibility
extern const char* kMPVOption_Subtitles_NoSecondarySubVisibility;
// --sub-clear-on-seek
extern const char* kMPVOption_Subtitles_SubClearOnSeek;
// --teletext-page=<1-999>
extern const char* kMPVOption_Subtitles_TeletextPage;
// --sub-past-video-end
extern const char* kMPVOption_Subtitles_SubPastVideoEnd;
// --sub-font=<name>
extern const char* kMPVOption_Subtitles_SubFont;
// --sub-font-size=<size>
extern const char* kMPVOption_Subtitles_SubFontSize;
// --sub-back-color=<color>
extern const char* kMPVOption_Subtitles_SubBackColor;
// --sub-blur=<0..20.0>
extern const char* kMPVOption_Subtitles_SubBlur;
// --sub-bold=<yes|no>
extern const char* kMPVOption_Subtitles_SubBold;
// --sub-italic=<yes|no>
extern const char* kMPVOption_Subtitles_SubItalic;
// --sub-border-color=<color>
extern const char* kMPVOption_Subtitles_SubBorderColor;
// --sub-border-size=<size>
extern const char* kMPVOption_Subtitles_SubBorderSize;
// --sub-color=<color>
extern const char* kMPVOption_Subtitles_SubColor;
// --sub-margin-x=<size>
extern const char* kMPVOption_Subtitles_SubMarginX;
// --sub-margin-y=<size>
extern const char* kMPVOption_Subtitles_SubMarginY;
// --sub-align-x=<left|center|right>
extern const char* kMPVOption_Subtitles_SubAlignX;
// --sub-align-y=<top|center|bottom>
extern const char* kMPVOption_Subtitles_SubAlignY;
// --sub-justify=<auto|left|center|right>
extern const char* kMPVOption_Subtitles_SubJustify;
// --sub-ass-justify=<yes|no>
extern const char* kMPVOption_Subtitles_SubAssJustify;
// --sub-shadow-color=<color>
extern const char* kMPVOption_Subtitles_SubShadowColor;
// --sub-shadow-offset=<size>
extern const char* kMPVOption_Subtitles_SubShadowOffset;
// --sub-spacing=<size>
extern const char* kMPVOption_Subtitles_SubSpacing;
// --sub-filter-sdh=<yes|no>
extern const char* kMPVOption_Subtitles_SubFilterSdh;
// --sub-filter-sdh-harder=<yes|no>
extern const char* kMPVOption_Subtitles_SubFilterSdhHarder;
// --sub-filter-regex-plain=<yes|no>
extern const char* kMPVOption_Subtitles_SubFilterRegexPlain;
// --sub-filter-regex-warn=<yes|no>
extern const char* kMPVOption_Subtitles_SubFilterRegexWarn;
// --sub-filter-regex-enable=<yes|no>
extern const char* kMPVOption_Subtitles_SubFilterRegexEnable;
// --sub-create-cc-track=<yes|no>
extern const char* kMPVOption_Subtitles_SubCreateCcTrack;
// --sub-font-provider=<auto|none|fontconfig>
extern const char* kMPVOption_Subtitles_SubFontProvider;

// --title=<string>
extern const char* kMPVOption_Window_Title;
// --screen=<default|0-32>
extern const char* kMPVOption_Window_Screen;
// --screen-name=<string>
extern const char* kMPVOption_Window_ScreenName;
// --fullscreen
extern const char* kMPVOption_Window_Fullscreen;
// --fs
extern const char* kMPVOption_Window_Fs;
// --fs-screen=<all|current|0-32>
extern const char* kMPVOption_Window_FsScreen;
// --fs-screen-name=<string>
extern const char* kMPVOption_Window_FsScreenName;
// --keep-open=<yes|no|always>
extern const char* kMPVOption_Window_KeepOpen;
// --keep-open-pause=<yes|no>
extern const char* kMPVOption_Window_KeepOpenPause;
// --image-display-duration=<seconds|inf>
extern const char* kMPVOption_Window_ImageDisplayDuration;
// --force-window=<yes|no|immediate>
extern const char* kMPVOption_Window_ForceWindow;
// --taskbar-progress
extern const char* kMPVOption_Window_TaskbarProgress;
// --no-taskbar-progress
extern const char* kMPVOption_Window_NoTaskbarProgress;
// --snap-window
extern const char* kMPVOption_Window_SnapWindow;
// --ontop
extern const char* kMPVOption_Window_Ontop;
// --ontop-level=<window|system|desktop|level>
extern const char* kMPVOption_Window_OntopLevel;
// --focus-on-open
extern const char* kMPVOption_Window_FocusOnOpen;
// --no-focus-on-open
extern const char* kMPVOption_Window_NoFocusOnOpen;
// --border
extern const char* kMPVOption_Window_Border;
// --no-border
extern const char* kMPVOption_Window_NoBorder;
// --on-all-workspaces
extern const char* kMPVOption_Window_OnAllWorkspaces;
// --geometry=<[W[xH]][+-x+-y][/WS]>
extern const char* kMPVOption_Window_Geometry;
// --autofit=<[W[xH]]>
extern const char* kMPVOption_Window_Autofit;
// --autofit-larger=<[W[xH]]>
extern const char* kMPVOption_Window_AutofitLarger;
// --autofit-smaller=<[W[xH]]>
extern const char* kMPVOption_Window_AutofitSmaller;
// --window-scale=<factor>
extern const char* kMPVOption_Window_WindowScale;
// --window-minimized=<yes|no>
extern const char* kMPVOption_Window_WindowMinimized;
// --window-maximized=<yes|no>
extern const char* kMPVOption_Window_WindowMaximized;
// --cursor-autohide=<number|no|always>
extern const char* kMPVOption_Window_CursorAutohide;
// --cursor-autohide-fs-only
extern const char* kMPVOption_Window_CursorAutohideFsOnly;
// --no-fixed-vo
extern const char* kMPVOption_Window_NoFixedVO;
// --fixed-vo
extern const char* kMPVOption_Window_FixedVO;
// --force-rgba-osd-rendering
extern const char* kMPVOption_Window_ForceRGBAOSDRendering;
// --force-window-position
extern const char* kMPVOption_Window_ForceWindowPosition;
// --no-keepaspect
extern const char* kMPVOption_Window_NoKeepAspect;
// --keepaspect
extern const char* kMPVOption_Window_KeepAspect;
// --no-keepaspect-window
extern const char* kMPVOption_Window_NoKeepAspectWindow;
// --keepaspect-window
extern const char* kMPVOption_Window_KeepAspectWindow;
// --monitoraspect=<ratio>
extern const char* kMPVOption_Window_Monitoraspect;
// --hidpi-window-scale
extern const char* kMPVOption_Window_HIDPIWindowScale;
// --no-hidpi-window-scale
extern const char* kMPVOption_Window_NoHIDPIWindowScale;
// --native-fs
extern const char* kMPVOption_Window_NativeFS;
// --no-native-fs
extern const char* kMPVOption_Window_NoNativeFS;
// --monitorpixelaspect=<ratio>
extern const char* kMPVOption_Window_Monitorpixelaspect;
// --stop-screensaver
extern const char* kMPVOption_Window_StopScreensaver;
// --no-stop-screensaver
extern const char* kMPVOption_Window_NoStopScreensaver;
// --wid=<ID>
extern const char* kMPVOption_Window_Wid;
// --no-window-dragging
extern const char* kMPVOption_Window_NoWindowDragging;
// --x11-name
extern const char* kMPVOption_Window_X11Name;
// --x11-netwm=<yes|no|auto>
extern const char* kMPVOption_Window_X11Netwm;
// --x11-bypass-compositor=<yes|no|fs-only|never>
extern const char* kMPVOption_Window_X11BypassCompositor;

// --cdrom-device=<path>
extern const char* kMPVOption_DiscDevices_CDROMDevice;
// --dvd-device=<path>
extern const char* kMPVOption_DiscDevices_DVDDevice;
// --bluray-device=<path>
extern const char* kMPVOption_DiscDevices_BlurayDevice;
// --cdda-speed=<value>
extern const char* kMPVOption_DiscDevices_CDDASpeed;
// --cdda-paranoia=<0-2>
extern const char* kMPVOption_DiscDevices_CDDAParanoia;
// --cdda-sector-size=<value>
extern const char* kMPVOption_DiscDevices_CDDASectorSize;
// --cdda-overlap=<value>
extern const char* kMPVOption_DiscDevices_CDDAOverlap;
// --cdda-toc-bias
extern const char* kMPVOption_DiscDevices_CDDATocBias;
// --cdda-toc-offset=<value>
extern const char* kMPVOption_DiscDevices_CDDATocOffset;
// --cdda-skip=<yes|no>
extern const char* kMPVOption_DiscDevices_CDDASkip;
// --cdda-cdtext=<yes|no>
extern const char* kMPVOption_DiscDevices_CDDACdtext;
// --dvd-speed=<speed>
extern const char* kMPVOption_DiscDevices_DVDSpeed;
// --dvd-angle=<ID>
extern const char* kMPVOption_DiscDevices_DVDAngle;

// --brightness=<-100-100>
extern const char* kMPVOption_Equalizer_Brightness;
// --contrast=<-100-100>
extern const char* kMPVOption_Equalizer_Contrast;
// --saturation=<-100-100>
extern const char* kMPVOption_Equalizer_Saturation;
// --gamma=<-100-100>
extern const char* kMPVOption_Equalizer_Gamma;
// --hue=<-100-100>
extern const char* kMPVOption_Equalizer_Hue;

// --demuxer=<[+]name>
extern const char* kMPVOption_Demuxer_Demuxer;
// --demuxer-lavf-analyzeduration=<value>
extern const char* kMPVOption_Demuxer_DemuxerLavfAnalyzeduration;
// --demuxer-lavf-probe-info=<yes|no|auto|nostreams>
extern const char* kMPVOption_Demuxer_DemuxerLavfProbeInfo;
// --demuxer-lavf-probescore=<1-100>
extern const char* kMPVOption_Demuxer_DemuxerLavfProbescore;
// --demuxer-lavf-allow-mimetype=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerLavfAllowMimetype;
// --demuxer-lavf-format=<name>
extern const char* kMPVOption_Demuxer_DemuxerLavfFormat;
// --demuxer-lavf-hacks=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerLavfHacks;
// --demuxer-lavf-o=<key>=<value>[
extern const char* kMPVOption_Demuxer_DemuxerLavfO;
// --demuxer-lavf-probesize=<value>
extern const char* kMPVOption_Demuxer_DemuxerLavfProbesize;
// --demuxer-lavf-buffersize=<value>
extern const char* kMPVOption_Demuxer_DemuxerLavfBuffersize;
// --demuxer-lavf-linearize-timestamps=<yes|no|auto>
extern const char* kMPVOption_Demuxer_DemuxerLavfLinearizeTimestamps;
// --demuxer-lavf-propagate-opts=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerLavfPropagateOpts;
// --demuxer-mkv-subtitle-preroll=<yes|index|no>
extern const char* kMPVOption_Demuxer_DemuxerMKVSubtitlePreroll;
// --mkv-subtitle-preroll
extern const char* kMPVOption_Demuxer_MKVSubtitlePreroll;
// --demuxer-mkv-subtitle-preroll-secs=<value>
extern const char* kMPVOption_Demuxer_DemuxerMKVSubtitlePrerollSecs;
// --demuxer-mkv-subtitle-preroll-secs-index=<value>
extern const char* kMPVOption_Demuxer_DemuxerMKVSubtitlePrerollSecsIndex;
// --demuxer-mkv-probe-start-time=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerMKVProbeStartTime;
// --demuxer-mkv-probe-video-duration=<yes|no|full>
extern const char* kMPVOption_Demuxer_DemuxerMKVProbeVideoDuration;
// --demuxer-rawaudio-channels=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawAudioChannels;
// --demuxer-rawaudio-format=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawAudioFormat;
// --demuxer-rawaudio-rate=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawAudioRate;
// --demuxer-rawvideo-fps=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoFps;
// --demuxer-rawvideo-w=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoW;
// --demuxer-rawvideo-h=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoH;
// --demuxer-rawvideo-format=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoFormat;
// --demuxer-rawvideo-mp-format=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoMpFormat;
// --demuxer-rawvideo-codec=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoCodec;
// --demuxer-rawvideo-size=<value>
extern const char* kMPVOption_Demuxer_DemuxerRawVideoSize;
// --demuxer-cue-codepage=<codepage>
extern const char* kMPVOption_Demuxer_DemuxerCueCodepage;
// --demuxer-max-bytes=<bytesize>
extern const char* kMPVOption_Demuxer_DemuxerMaxBytes;
// --demuxer-max-back-bytes=<bytesize>
extern const char* kMPVOption_Demuxer_DemuxerMaxBackBytes;
// --demuxer-donate-buffer=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerDonateBuffer;
// --demuxer-seekable-cache=<yes|no|auto>
extern const char* kMPVOption_Demuxer_DemuxerSeekableCache;
// --demuxer-force-retry-on-eof=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerForceRetryOnEof;
// --demuxer-thread=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerThread;
// --demuxer-termination-timeout=<seconds>
extern const char* kMPVOption_Demuxer_DemuxerTerminationTimeout;
// --demuxer-readahead-secs=<seconds>
extern const char* kMPVOption_Demuxer_DemuxerReadaheadSecs;
// --prefetch-playlist=<yes|no>
extern const char* kMPVOption_Demuxer_PrefetchPlaylist;
// --force-seekable=<yes|no>
extern const char* kMPVOption_Demuxer_ForceSeekable;
// --demuxer-cache-wait=<yes|no>
extern const char* kMPVOption_Demuxer_DemuxerCacheWait;
// --rar-list-all-volumes=<yes|no>
extern const char* kMPVOption_Demuxer_RarListAllVolumes;

/** --native-keyrepeat */
extern const char* kMPVOption_Input_NativeKeyrepeat;
/** --input-ar-delay */
extern const char* kMPVOption_Input_InputARDelay;
/** --input-ar-rate */
extern const char* kMPVOption_Input_InputARRate;
/** --input-conf=<filename> */
extern const char* kMPVOption_Input_InputConf;
/** --no-input-default-bindings */
extern const char* kMPVOption_Input_NoInputDefaultBindings;
/** --no-input-builtin-bindings */
extern const char* kMPVOption_Input_NoInputBuiltinBindings;
/** --input-cmdlist */
extern const char* kMPVOption_Input_InputCmdlist;
/** --input-doubleclick-time=<milliseconds> */
extern const char* kMPVOption_Input_InputDoubleclickTime;
/** --input-keylist */
extern const char* kMPVOption_Input_InputKeylist;
/** --input-key-fifo-size=<2-65000> */
extern const char* kMPVOption_Input_InputKeyFIFOSize;
/** --input-test */
extern const char* kMPVOption_Input_InputTest;
/** --input-terminal */
extern const char* kMPVOption_Input_InputTerminal;
/** --no-input-terminal */
extern const char* kMPVOption_Input_NoInputTerminal;
/** --input-ipc-server=<filename> */
extern const char* kMPVOption_Input_InputIPCServer;
/** --input-ipc-client=fd://<N> */
extern const char* kMPVOption_Input_InputIPCClient;
/** --input-gamepad=<yes|no> */
extern const char* kMPVOption_Input_InputGamepad;
/** --input-cursor */
extern const char* kMPVOption_Input_InputCursor;
/** --no-input-cursor */
extern const char* kMPVOption_Input_NoInputCursor;
/** --input-media-keys=<yes|no> */
extern const char* kMPVOption_Input_InputMediaKeys;
/** --input-right-alt-gr */
extern const char* kMPVOption_Input_InputRightAltGr;
/** --no-input-right-alt-gr */
extern const char* kMPVOption_Input_NoInputRightAltGr;
/** --input-vo-keyboard=<yes|no> */
extern const char* kMPVOption_Input_InputVOKeyboard;

// --osc
extern const char* kMPVOption_OSD_Osc;
// --no-osc
extern const char* kMPVOption_OSD_NoOsc;
// --no-osd-bar
extern const char* kMPVOption_OSD_NoOSDBar;
// --osd-bar
extern const char* kMPVOption_OSD_OSDBar;
// --osd-on-seek=<no
extern const char* kMPVOption_OSD_OSDOnSeek;
// --osd-duration=<time>
extern const char* kMPVOption_OSD_OSDDuration;
// --osd-font=<name>
extern const char* kMPVOption_OSD_OSDFont;
// --osd-font-size=<size>
extern const char* kMPVOption_OSD_OSDFontSize;
// --osd-msg1=<string>
extern const char* kMPVOption_OSD_OSDMsg1;
// --osd-msg2=<string>
extern const char* kMPVOption_OSD_OSDMsg2;
// --osd-msg3=<string>
extern const char* kMPVOption_OSD_OSDMsg3;
// --osd-status-msg=<string>
extern const char* kMPVOption_OSD_OSDStatusMsg;
// --osd-playing-msg=<string>
extern const char* kMPVOption_OSD_OSDPlayingMsg;
// --osd-bar-align-x=<-1-1>
extern const char* kMPVOption_OSD_OSDBarAlignX;
// --osd-bar-align-y=<-1-1>
extern const char* kMPVOption_OSD_OSDBarAlignY;
// --osd-bar-w=<1-100>
extern const char* kMPVOption_OSD_OSDBarW;
// --osd-bar-h=<0.1-50>
extern const char* kMPVOption_OSD_OSDBarH;
// --osd-back-color=<color>
extern const char* kMPVOption_OSD_OSDBackColor;
// --osd-blur=<0..20.0>
extern const char* kMPVOption_OSD_OSDBlur;
// --osd-bold=<yes|no>
extern const char* kMPVOption_OSD_OSDBold;
// --osd-italic=<yes|no>
extern const char* kMPVOption_OSD_OSDItalic;
// --osd-border-color=<color>
extern const char* kMPVOption_OSD_OSDBorderColor;
// --osd-border-size=<size>
extern const char* kMPVOption_OSD_OSDBorderSize;
// --osd-color=<color>
extern const char* kMPVOption_OSD_OSDColor;
// --osd-fractions
extern const char* kMPVOption_OSD_OSDFractions;
// --osd-level=<0-3>
extern const char* kMPVOption_OSD_OSDLevel;
// --osd-margin-x=<size>
extern const char* kMPVOption_OSD_OSDMarginX;
// --osd-margin-y=<size>
extern const char* kMPVOption_OSD_OSDMarginY;
// --osd-align-x=<left|center|right>
extern const char* kMPVOption_OSD_OSDAlignX;
// --osd-align-y=<top|center|bottom>
extern const char* kMPVOption_OSD_OSDAlignY;
// --osd-scale=<factor>
extern const char* kMPVOption_OSD_OSDScale;
// --osd-scale-by-window=<yes|no>
extern const char* kMPVOption_OSD_OSDScaleByWindow;
// --osd-shadow-color=<color>
extern const char* kMPVOption_OSD_OSDShadowColor;
// --osd-shadow-offset=<size>
extern const char* kMPVOption_OSD_OSDShadowOffset;
// --osd-spacing=<size>
extern const char* kMPVOption_OSD_OSDSpacing;
// --video-osd=<yes|no>
extern const char* kMPVOption_OSD_VideoOSD;
// --osd-font-provider=<...>
extern const char* kMPVOption_OSD_OSDFontProvider;

// --screenshot-format=<type>
extern const char* kMPVOption_Screenshot_ScreenshotFormat;
// --screenshot-tag-colorspace=<yes|no>
extern const char* kMPVOption_Screenshot_ScreenshotTagColorspace;
// --screenshot-high-bit-depth=<yes|no>
extern const char* kMPVOption_Screenshot_ScreenshotHighBitDepth;
// --screenshot-template=<template>
extern const char* kMPVOption_Screenshot_ScreenshotTemplate;
// --screenshot-directory=<path>
extern const char* kMPVOption_Screenshot_ScreenshotDirectory;
// --screenshot-jpeg-quality=<0-100>
extern const char* kMPVOption_Screenshot_ScreenshotJpegQuality;
// --screenshot-jpeg-source-chroma=<yes|no>
extern const char* kMPVOption_Screenshot_ScreenshotJpegSourceChroma;
// --screenshot-png-compression=<0-9>
extern const char* kMPVOption_Screenshot_ScreenshotPngCompression;
// --screenshot-png-filter=<0-5>
extern const char* kMPVOption_Screenshot_ScreenshotPngFilter;
// --screenshot-webp-lossless=<yes|no>
extern const char* kMPVOption_Screenshot_ScreenshotWebpLossless;
// --screenshot-webp-quality=<0-100>
extern const char* kMPVOption_Screenshot_ScreenshotWebpQuality;
// --screenshot-webp-compression=<0-6>
extern const char* kMPVOption_Screenshot_ScreenshotWebpCompression;
// --screenshot-sw=<yes|no>
extern const char* kMPVOption_Screenshot_ScreenshotSw;

// --sws-scaler=<name>
extern const char* kMPVOption_SoftwareScaler_swsScaler;
// --sws-lgb=<0-100>
extern const char* kMPVOption_SoftwareScaler_swsLgb;
// --sws-cgb=<0-100>
extern const char* kMPVOption_SoftwareScaler_swsCgb;
// --sws-ls=<-100-100>
extern const char* kMPVOption_SoftwareScaler_swsLs;
// --sws-cs=<-100-100>
extern const char* kMPVOption_SoftwareScaler_swsCs;
// --sws-chs=<h>
extern const char* kMPVOption_SoftwareScaler_swsChs;
// --sws-cvs=<v>
extern const char* kMPVOption_SoftwareScaler_swsCvs;
// --sws-bitexact=<yes|no>
extern const char* kMPVOption_SoftwareScaler_swsBitexact;
// --sws-fast=<yes|no>
extern const char* kMPVOption_SoftwareScaler_swsFast;
// --sws-allow-zimg=<yes|no>
extern const char* kMPVOption_SoftwareScaler_swsAllowZimg;
// --zimg-scaler=<point|bilinear|bicubic|spline16|spline36|lanczos>
extern const char* kMPVOption_SoftwareScaler_zimgScaler;
// --zimg-scaler-param-a=<default|float>
extern const char* kMPVOption_SoftwareScaler_zimgScalerParamA;
// --zimg-scaler-param-b=<default|float>
extern const char* kMPVOption_SoftwareScaler_zimgScalerParamB;
// --zimg-scaler-chroma=...
extern const char* kMPVOption_SoftwareScaler_zimgScalerChroma;
// --zimg-scaler-chroma-param-a
extern const char* kMPVOption_SoftwareScaler_zimgScalerChromaParamA;
// --zimg-scaler-chroma-param-b
extern const char* kMPVOption_SoftwareScaler_zimgScalerChromaParamB;
// --zimg-dither=<no|ordered|random|error-diffusion>
extern const char* kMPVOption_SoftwareScaler_zimgDither;
// --zimg-threads=<auto|integer>
extern const char* kMPVOption_SoftwareScaler_zimgThreads;
// --zimg-fast=<yes|no>
extern const char* kMPVOption_SoftwareScaler_zimgFast;

// --audio-resample-filter-size=<length>
extern const char* kMPVOption_AudioResampler_AudioResampleFilterSize;
// --audio-resample-phase-shift=<count>
extern const char* kMPVOption_AudioResampler_AudioResamplePhaseShift;
// --audio-resample-cutoff=<cutoff>
extern const char* kMPVOption_AudioResampler_AudioResampleCutoff;
// --audio-resample-linear=<yes|no>
extern const char* kMPVOption_AudioResampler_AudioResampleLinear;
// --audio-normalize-downmix=<yes|no>
extern const char* kMPVOption_AudioResampler_AudioNormalizeDownmix;
// --audio-resample-max-output-size=<length>
extern const char* kMPVOption_AudioResampler_AudioResampleMaxOutputSize;
// --audio-swresample-o=<string>
extern const char* kMPVOption_AudioResampler_AudioSwresampleO;

// --quiet
extern const char* kMPVOption_Terminal_Quiet;
// --really-quiet
extern const char* kMPVOption_Terminal_ReallyQuiet;
// --no-terminal
extern const char* kMPVOption_Terminal_NoTerminal;
// --terminal
extern const char* kMPVOption_Terminal_Terminal;
// --no-msg-color
extern const char* kMPVOption_Terminal_NoMsgColor;
// --msg-level=<module1=level1
extern const char* kMPVOption_Terminal_MsgLevel;
// --term-osd=<auto|no|force>
extern const char* kMPVOption_Terminal_TermOSD;
// --term-osd-bar
extern const char* kMPVOption_Terminal_TermOSDBar;
// --no-term-osd-bar
extern const char* kMPVOption_Terminal_NoTermOSDBar;
// --term-osd-bar-chars=<string>
extern const char* kMPVOption_Terminal_TermOSDBarChars;
// --term-playing-msg=<string>
extern const char* kMPVOption_Terminal_TermPlayingMsg;
// --term-status-msg=<string>
extern const char* kMPVOption_Terminal_TermStatusMsg;
// --term-title=<string>
extern const char* kMPVOption_Terminal_TermTitle;
// --msg-module
extern const char* kMPVOption_Terminal_MsgModule;
// --msg-time
extern const char* kMPVOption_Terminal_MsgTime;

// --cache=<yes|no|auto>
extern const char* kMPVOption_Cache_Cache;
// --no-cache
extern const char* kMPVOption_Cache_NoCache;
// --cache-secs=<seconds>
extern const char* kMPVOption_Cache_CacheSecs;
// --cache-on-disk=<yes|no>
extern const char* kMPVOption_Cache_CacheOnDisk;
// --cache-dir=<path>
extern const char* kMPVOption_Cache_CacheDir;
// --cache-pause=<yes|no>
extern const char* kMPVOption_Cache_CachePause;
// --cache-pause-wait=<seconds>
extern const char* kMPVOption_Cache_CachePauseWait;
// --cache-pause-initial=<yes|no>
extern const char* kMPVOption_Cache_CachePauseInitial;
// --cache-unlink-files=<immediate|whendone|no>
extern const char* kMPVOption_Cache_CacheUnlinkFiles;
// --stream-buffer-size=<bytesize>
extern const char* kMPVOption_Cache_StreamBufferSize;
// --vd-queue-enable=<yes|no>
extern const char* kMPVOption_Cache_VDQueueEnable;
//  --ad-queue-enable
extern const char* kMPVOption_Cache_ADQueueEnable;
// --vd-queue-max-bytes=<bytesize>
extern const char* kMPVOption_Cache_VDQueueMaxBytes;
// --ad-queue-max-bytes
extern const char* kMPVOption_Cache_ADQueueMaxBytes;
// --vd-queue-max-samples=<int>
extern const char* kMPVOption_Cache_VDQueueMaxSamples;
// --ad-queue-max-samples
extern const char* kMPVOption_Cache_ADQueueMaxSamples;
// --vd-queue-max-secs=<seconds>
extern const char* kMPVOption_Cache_VDQueueMaxSecs;
// --ad-queue-max-secs
extern const char* kMPVOption_Cache_ADQueueMaxSecs;

// --user-agent=<string>
extern const char* kMPVOption_Network_UserAgent;
// --cookies
extern const char* kMPVOption_Network_Cookies;
// --no-cookies
extern const char* kMPVOption_Network_NoCookies;
// --cookies-file=<filename>
extern const char* kMPVOption_Network_CookiesFile;
// --http-header-fields=<field1
extern const char* kMPVOption_Network_HTTPHeaderFields;
// --http-proxy=<proxy>
extern const char* kMPVOption_Network_HTTPProxy;
// --tls-ca-file=<filename>
extern const char* kMPVOption_Network_TLSCAFile;
// --tls-verify
extern const char* kMPVOption_Network_TLSVerify;
// --tls-cert-file
extern const char* kMPVOption_Network_TLSCertFile;
// --tls-key-file
extern const char* kMPVOption_Network_TLSKeyFile;
// --referrer=<string>
extern const char* kMPVOption_Network_Referrer;
// --network-timeout=<seconds>
extern const char* kMPVOption_Network_NetworkTimeout;
// --rtsp-transport=<lavf|udp|udp_multicast|tcp|http>
extern const char* kMPVOption_Network_RTSPTransport;
// --hls-bitrate=<no|min|max|<rate>>
extern const char* kMPVOption_Network_HLSBitrate;

// --dvbin-prog=<string>
extern const char* kMPVOption_DVB_DVBinProg;
// --dvbin-card=<0-15>
extern const char* kMPVOption_DVB_DVBinCard;
// --dvbin-file=<filename>
extern const char* kMPVOption_DVB_DVBinFile;
// --dvbin-timeout=<1-30>
extern const char* kMPVOption_DVB_DVBinTimeout;
// --dvbin-full-transponder=<yes|no>
extern const char* kMPVOption_DVB_DVBinFullTransponder;
// --dvbin-channel-switch-offset=<integer>
extern const char* kMPVOption_DVB_DVBinChannelSwitchOffset;

// --alsa-device=<device>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSADevice;
// --alsa-resample=yes
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAResample;
// --alsa-mixer-device=<device>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAMixerDevice;
// --alsa-mixer-name=<name>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAMixerName;
// --alsa-mixer-index=<number>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAMixerIndex;
// --alsa-non-interleaved
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSANonInterleaved;
// --alsa-ignore-chmap
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAIgnoreChmap;
// --alsa-buffer-time=<microseconds>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSABufferTime;
// --alsa-periods=<number>
extern const char* kMPVOption_ALSAAudioOutputOptions_ALSAPeriods;

// --scale=<filter>
extern const char* kMPVOption_GPURendererOptions_Scale;
// --cscale=<filter>
extern const char* kMPVOption_GPURendererOptions_CScale;
// --dscale=<filter>
extern const char* kMPVOption_GPURendererOptions_DScale;
// --tscale=<filter>
extern const char* kMPVOption_GPURendererOptions_TScale;
// --scale-param1=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleParam1;
// --scale-param2=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleParam2;
// --cscale-param1=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleParam1;
// --cscale-param2=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleParam2;
// --dscale-param1=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleParam1;
// --dscale-param2=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleParam2;
// --tscale-param1=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleParam1;
// --tscale-param2=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleParam2;
// --scale-blur=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleBlur;
// --scale-wblur=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleWblur;
// --cscale-blur=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleBlur;
// --cscale-wblur=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleWblur;
// --dscale-blur=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleBlur;
// --dscale-wblur=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleWblur;
// --tscale-blur=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleBlur;
// --tscale-wblur=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleWblur;
// --scale-clamp=<0.0-1.0>
extern const char* kMPVOption_GPURendererOptions_ScaleClamp;
// --cscale-clamp
extern const char* kMPVOption_GPURendererOptions_CScaleClamp;
// --dscale-clamp
extern const char* kMPVOption_GPURendererOptions_DScaleClamp;
// --tscale-clamp
extern const char* kMPVOption_GPURendererOptions_TScaleClamp;
// --scale-cutoff=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleCutoff;
// --cscale-cutoff=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleCutoff;
// --dscale-cutoff=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleCutoff;
// --scale-taper=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleTaper;
// --scale-wtaper=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleWtaper;
// --dscale-taper=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleTaper;
// --dscale-wtaper=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleWtaper;
// --cscale-taper=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleTaper;
// --cscale-wtaper=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleWtaper;
// --tscale-taper=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleTaper;
// --tscale-wtaper=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleWtaper;
// --scale-radius=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleRadius;
// --cscale-radius=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleRadius;
// --dscale-radius=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleRadius;
// --tscale-radius=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleRadius;
// --scale-antiring=<value>
extern const char* kMPVOption_GPURendererOptions_ScaleAntiring;
// --cscale-antiring=<value>
extern const char* kMPVOption_GPURendererOptions_CScaleAntiring;
// --dscale-antiring=<value>
extern const char* kMPVOption_GPURendererOptions_DScaleAntiring;
// --tscale-antiring=<value>
extern const char* kMPVOption_GPURendererOptions_TScaleAntiring;
// --scale-window=<window>
extern const char* kMPVOption_GPURendererOptions_ScaleWindow;
// --cscale-window=<window>
extern const char* kMPVOption_GPURendererOptions_CScaleWindow;
// --dscale-window=<window>
extern const char* kMPVOption_GPURendererOptions_DScaleWindow;
// --tscale-window=<window>
extern const char* kMPVOption_GPURendererOptions_TScaleWindow;
// --scale-wparam=<window>
extern const char* kMPVOption_GPURendererOptions_ScaleWparam;
// --cscale-wparam=<window>
extern const char* kMPVOption_GPURendererOptions_CScaleWparam;
// --tscale-wparam=<window>
extern const char* kMPVOption_GPURendererOptions_TScaleWparam;
// --scaler-lut-size=<4..10>
extern const char* kMPVOption_GPURendererOptions_ScalerLUTSize;
// --scaler-resizes-only
extern const char* kMPVOption_GPURendererOptions_ScalerResizesOnly;
// --correct-downscaling
extern const char* kMPVOption_GPURendererOptions_CorrectDownscaling;
// --linear-downscaling
extern const char* kMPVOption_GPURendererOptions_LinearDownscaling;
// --linear-upscaling
extern const char* kMPVOption_GPURendererOptions_LinearUpscaling;
// --sigmoid-upscaling
extern const char* kMPVOption_GPURendererOptions_SigmoidUpscaling;
// --sigmoid-center
extern const char* kMPVOption_GPURendererOptions_SigmoidCenter;
// --sigmoid-slope
extern const char* kMPVOption_GPURendererOptions_SigmoidSlope;
// --interpolation
extern const char* kMPVOption_GPURendererOptions_Interpolation;
// --interpolation-threshold=<0..1
extern const char* kMPVOption_GPURendererOptions_InterpolationThreshold;
// --opengl-pbo
extern const char* kMPVOption_GPURendererOptions_OpenGLPbo;
// --dither-depth=<N|no|auto>
extern const char* kMPVOption_GPURendererOptions_DitherDepth;
// --dither-size-fruit=<2-8>
extern const char* kMPVOption_GPURendererOptions_DitherSizeFruit;
// --dither=<fruit|ordered|error-diffusion|no>
extern const char* kMPVOption_GPURendererOptions_Dither;
// --temporal-dither
extern const char* kMPVOption_GPURendererOptions_TemporalDither;
// --temporal-dither-period=<1-128>
extern const char* kMPVOption_GPURendererOptions_TemporalDitherPeriod;
// --error-diffusion=<kernel>
extern const char* kMPVOption_GPURendererOptions_ErrorDiffusion;
// --gpu-debug
extern const char* kMPVOption_GPURendererOptions_GPUDebug;
// --opengl-swapinterval=<n>
extern const char* kMPVOption_GPURendererOptions_OpenGLSwapinterval;
// --vulkan-device=<device name>
extern const char* kMPVOption_GPURendererOptions_VulkanDevice;
// --vulkan-swap-mode=<mode>
extern const char* kMPVOption_GPURendererOptions_VulkanSwapMode;
// --vulkan-queue-count=<1..8>
extern const char* kMPVOption_GPURendererOptions_VulkanQueueCount;
// --vulkan-async-transfer
extern const char* kMPVOption_GPURendererOptions_VulkanAsyncTransfer;
// --vulkan-async-compute
extern const char* kMPVOption_GPURendererOptions_VulkanAsyncCompute;
// --vulkan-disable-events
extern const char* kMPVOption_GPURendererOptions_VulkanDisableEvents;
// --vulkan-display-display=<n>
extern const char* kMPVOption_GPURendererOptions_VulkanDisplayDisplay;
// --vulkan-display-mode=<n>
extern const char* kMPVOption_GPURendererOptions_VulkanDisplayMode;
// --vulkan-display-plane=<n>
extern const char* kMPVOption_GPURendererOptions_VulkanDisplayPlane;
// --d3d11-exclusive-fs=<yes|no>
extern const char* kMPVOption_GPURendererOptions_D3D11ExclusiveFs;
// --d3d11-warp=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_D3D11Warp;
// --d3d11-feature-level=<12_1|12_0|11_1|11_0|10_1|10_0|9_3|9_2|9_1>
extern const char* kMPVOption_GPURendererOptions_D3D11FeatureLevel;
// --d3d11-flip=<yes|no>
extern const char* kMPVOption_GPURendererOptions_D3D11Flip;
// --d3d11-sync-interval=<0..4>
extern const char* kMPVOption_GPURendererOptions_D3D11SyncInterval;
// --d3d11-adapter=<adapter name|help>
extern const char* kMPVOption_GPURendererOptions_D3D11Adapter;
// --d3d11-output-format=<auto|rgba8|bgra8|rgb10_a2|rgba16f>
extern const char* kMPVOption_GPURendererOptions_D3D11OutputFormat;
// --d3d11-output-csp=<auto|srgb|linear|pq|bt.2020>
extern const char* kMPVOption_GPURendererOptions_D3D11OutputCsp;
// --d3d11va-zero-copy=<yes|no>
extern const char* kMPVOption_GPURendererOptions_D3D11vaZeroCopy;
// --wayland-app-id=<string>
extern const char* kMPVOption_GPURendererOptions_WaylandAppId;
// --wayland-disable-vsync=<yes|no>
extern const char* kMPVOption_GPURendererOptions_WaylandDisableVsync;
// --wayland-edge-pixels-pointer=<value>
extern const char* kMPVOption_GPURendererOptions_WaylandEdgePixelsPointer;
// --wayland-edge-pixels-touch=<value>
extern const char* kMPVOption_GPURendererOptions_WaylandEdgePixelsTouch;
// --spirv-compiler=<compiler>
extern const char* kMPVOption_GPURendererOptions_SPIRVCompiler;
// --glsl-shader=<file>
extern const char* kMPVOption_GPURendererOptions_GLSLShader;
// --glsl-shaders=<file-list>
extern const char* kMPVOption_GPURendererOptions_GLSLShaders;
// --deband
extern const char* kMPVOption_GPURendererOptions_Deband;
// --deband-iterations=<1..16>
extern const char* kMPVOption_GPURendererOptions_DebandIterations;
// --deband-threshold=<0..4096>
extern const char* kMPVOption_GPURendererOptions_DebandThreshold;
// --deband-range=<1..64>
extern const char* kMPVOption_GPURendererOptions_DebandRange;
// --deband-grain=<0..4096>
extern const char* kMPVOption_GPURendererOptions_DebandGrain;
// --sharpen=<value>
extern const char* kMPVOption_GPURendererOptions_Sharpen;
// --opengl-glfinish
extern const char* kMPVOption_GPURendererOptions_OpenGLGlfinish;
// --opengl-waitvsync
extern const char* kMPVOption_GPURendererOptions_OpenGLWaitvsync;
// --opengl-dwmflush=<no|windowed|yes|auto>
extern const char* kMPVOption_GPURendererOptions_OpenGLDWMFlush;
// --angle-d3d11-feature-level=<11_0|10_1|10_0|9_3>
extern const char* kMPVOption_GPURendererOptions_AngleD3D11FeatureLevel;
// --angle-d3d11-warp=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_AngleD3D11Warp;
// --angle-egl-windowing=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_AngleEglWindowing;
// --angle-flip=<yes|no>
extern const char* kMPVOption_GPURendererOptions_AngleFlip;
// --angle-renderer=<d3d9|d3d11|auto>
extern const char* kMPVOption_GPURendererOptions_AngleRenderer;
// --macos-force-dedicated-gpu=<yes|no>
extern const char* kMPVOption_GPURendererOptions_MacOSForceDedicatedGPU;
// --cocoa-cb-sw-renderer=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_CocoaCBSwRenderer;
// --cocoa-cb-10bit-context=<yes|no>
extern const char* kMPVOption_GPURendererOptions_CocoaCB10bitContext;
// --macos-title-bar-appearance=<appearance>
extern const char* kMPVOption_GPURendererOptions_MacOSTitleBarAppearance;
// --macos-title-bar-material=<material>
extern const char* kMPVOption_GPURendererOptions_MacOSTitleBarMaterial;
// --macos-title-bar-color=<color>
extern const char* kMPVOption_GPURendererOptions_MacOSTitleBarColor;
// --macos-fs-animation-duration=<default|0-1000>
extern const char* kMPVOption_GPURendererOptions_MacOSFsAnimationDuration;
// --macos-app-activation-policy=<regular|accessory|prohibited>
extern const char* kMPVOption_GPURendererOptions_MacOSAppActivationPolicy;
// --macos-geometry-calculation=<visible|whole>
extern const char* kMPVOption_GPURendererOptions_MacOSGeometryCalculation;
// --android-surface-size=<WxH>
extern const char* kMPVOption_GPURendererOptions_AndroidSurfaceSize;
// --gpu-sw
extern const char* kMPVOption_GPURendererOptions_GPUSw;
// --gpu-context=<sys>
extern const char* kMPVOption_GPURendererOptions_GPUContext;
// --gpu-api=<type>
extern const char* kMPVOption_GPURendererOptions_GPUAPI;
// --opengl-es=<mode>
extern const char* kMPVOption_GPURendererOptions_OpenGLEs;
// --fbo-format=<fmt>
extern const char* kMPVOption_GPURendererOptions_FBOFormat;
// --gamma-factor=<0.1..2.0>
extern const char* kMPVOption_GPURendererOptions_GammaFactor;
// --gamma-auto
extern const char* kMPVOption_GPURendererOptions_GammaAuto;
// --target-prim=<value>
extern const char* kMPVOption_GPURendererOptions_TargetPrim;
// --target-trc=<value>
extern const char* kMPVOption_GPURendererOptions_TargetTrc;
// --target-peak=<auto|nits>
extern const char* kMPVOption_GPURendererOptions_TargetPeak;
// --tone-mapping=<value>
extern const char* kMPVOption_GPURendererOptions_ToneMapping;
// --tone-mapping-param=<value>
extern const char* kMPVOption_GPURendererOptions_ToneMappingParam;
// --tone-mapping-max-boost=<1.0..10.0>
extern const char* kMPVOption_GPURendererOptions_ToneMappingMaxBoost;
// --hdr-compute-peak=<auto|yes|no>
extern const char* kMPVOption_GPURendererOptions_HDRComputePeak;
// --hdr-peak-decay-rate=<1.0..1000.0>
extern const char* kMPVOption_GPURendererOptions_HDRPeakDecayRate;
// --hdr-scene-threshold-low=<0.0..100.0>
extern const char* kMPVOption_GPURendererOptions_HDRSceneThresholdLow;
// --hdr-scene-threshold-high=<0.0..100.0>
extern const char* kMPVOption_GPURendererOptions_HDRSceneThresholdHigh;
// --tone-mapping-desaturate=<0.0..1.0>
extern const char* kMPVOption_GPURendererOptions_ToneMappingDesaturate;
// --tone-mapping-desaturate-exponent=<0.0..20.0>
extern const char* kMPVOption_GPURendererOptions_ToneMappingDesaturateExponent;
// --gamut-warning
extern const char* kMPVOption_GPURendererOptions_GamutWarning;
// --gamut-clipping
extern const char* kMPVOption_GPURendererOptions_GamutClipping;
// --use-embedded-icc-profile
extern const char* kMPVOption_GPURendererOptions_UseEmbeddedICCProfile;
// --icc-profile=<file>
extern const char* kMPVOption_GPURendererOptions_ICCProfile;
// --icc-profile-auto
extern const char* kMPVOption_GPURendererOptions_ICCProfileAuto;
// --icc-cache-dir=<dirname>
extern const char* kMPVOption_GPURendererOptions_ICCCacheDir;
// --icc-intent=<value>
extern const char* kMPVOption_GPURendererOptions_ICCIntent;
// --icc-3dlut-size=<r>x<g>x<b>
extern const char* kMPVOption_GPURendererOptions_ICC3DLUTSize;
// --icc-force-contrast=<no|0-1000000|inf>
extern const char* kMPVOption_GPURendererOptions_ICCForceContrast;
// --blend-subtitles=<yes|video|no>
extern const char* kMPVOption_GPURendererOptions_BlendSubtitles;
// --alpha=<blend-tiles|blend|yes|no>
extern const char* kMPVOption_GPURendererOptions_Alpha;
// --opengl-rectangle-textures
extern const char* kMPVOption_GPURendererOptions_OpenGLRectangleTextures;
// --background=<color>
extern const char* kMPVOption_GPURendererOptions_Background;
// --gpu-tex-pad-x
extern const char* kMPVOption_GPURendererOptions_GPUTexPadX;
// --gpu-tex-pad-y
extern const char* kMPVOption_GPURendererOptions_GPUTexPadY;
// --opengl-early-flush=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_OpenGLEarlyFlush;
// --gpu-dumb-mode=<yes|no|auto>
extern const char* kMPVOption_GPURendererOptions_GPUDumbMode;
// --gpu-shader-cache-dir=<dirname>
extern const char* kMPVOption_GPURendererOptions_GPUShaderCacheDir;

// --display-tags=tag1
extern const char* kMPVOption_Miscellaneous_DisplayTags;
// --mc=<seconds/frame>
extern const char* kMPVOption_Miscellaneous_MC;
// --autosync=<factor>
extern const char* kMPVOption_Miscellaneous_Autosync;
// --video-timing-offset=<seconds>
extern const char* kMPVOption_Miscellaneous_VideoTimingOffset;
// --video-sync=<audio|...>
extern const char* kMPVOption_Miscellaneous_VideoSync;
// --video-sync-max-factor=<value>
extern const char* kMPVOption_Miscellaneous_VideoSyncMaxFactor;
// --video-sync-max-video-change=<value>
extern const char* kMPVOption_Miscellaneous_VideoSyncMaxVideoChange;
// --video-sync-max-audio-change=<value>
extern const char* kMPVOption_Miscellaneous_VideoSyncMaxAudioChange;
// --mf-fps=<value>
extern const char* kMPVOption_Miscellaneous_MfFPS;
// --mf-type=<value>
extern const char* kMPVOption_Miscellaneous_MfType;
// --stream-dump=<destination-filename>
extern const char* kMPVOption_Miscellaneous_StreamDump;
// --stream-lavf-o=opt1=value1
extern const char* kMPVOption_Miscellaneous_StreamLavfO;
// --vo-mmcss-profile=<name>
extern const char* kMPVOption_Miscellaneous_VOMMCSSProfile;
// --priority=<prio>
extern const char* kMPVOption_Miscellaneous_Priority;
// --force-media-title=<string>
extern const char* kMPVOption_Miscellaneous_ForceMediaTitle;
// --external-files=<file-list>
extern const char* kMPVOption_Miscellaneous_ExternalFiles;
// --external-file=<file>
extern const char* kMPVOption_Miscellaneous_ExternalFile;
// --cover-art-files=<file-list>
extern const char* kMPVOption_Miscellaneous_CoverArtFiles;
// --cover-art-file=<file>
extern const char* kMPVOption_Miscellaneous_CoverArtFile;
// --cover-art-auto=<no|exact|fuzzy|all>
extern const char* kMPVOption_Miscellaneous_CoverArtAuto;
// --autoload-files=<yes|no>
extern const char* kMPVOption_Miscellaneous_AutoloadFiles;
// --record-file=<file>
extern const char* kMPVOption_Miscellaneous_RecordFile;
// --stream-record=<file>
extern const char* kMPVOption_Miscellaneous_StreamRecord;
// --lavfi-complex=<string>
extern const char* kMPVOption_Miscellaneous_LavfiComplex;
// --metadata-codepage=<codepage>
extern const char* kMPVOption_Miscellaneous_MetadataCodepage;

// --unittest=<name>
extern const char* kMPVOption_Debugging_Unittest;

// ignore
extern const char* kMPVCommand_Ignore;
// seek <target> [<flags>]
extern const char* kMPVCommand_Seek;
// revert-seek [<flags>]
extern const char* kMPVCommand_RevertSeek;
// frame-step
extern const char* kMPVCommand_FrameStep;
// frame-back-step
extern const char* kMPVCommand_FrameBackStep;
// set <name> <value>
extern const char* kMPVCommand_Set;
// add <name> [<value>]
extern const char* kMPVCommand_Add;
// cycle <name> [<value>]
extern const char* kMPVCommand_Cycle;
// multiply <name> <value>
extern const char* kMPVCommand_Multiply;
// screenshot <flags>
extern const char* kMPVCommand_Screenshot;
// screenshot-to-file <filename> <flags>
extern const char* kMPVCommand_ScreenshotToFile;
// playlist-next <flags>
extern const char* kMPVCommand_PlaylistNext;
// playlist-prev <flags>
extern const char* kMPVCommand_PlaylistPrev;
// playlist-play-index <integer|current|none>
extern const char* kMPVCommand_PlaylistPlayIndex;
// loadfile <url> [<flags> [<options>]]
extern const char* kMPVCommand_Loadfile;
// loadlist <url> [<flags>]
extern const char* kMPVCommand_Loadlist;
// playlist-clear
extern const char* kMPVCommand_PlaylistClear;
// playlist-remove <index>
extern const char* kMPVCommand_PlaylistRemove;
// playlist-move <index1> <index2>
extern const char* kMPVCommand_PlaylistMove;
// playlist-shuffle
extern const char* kMPVCommand_PlaylistShuffle;
// playlist-unshuffle
extern const char* kMPVCommand_PlaylistUnshuffle;
// run <command> [<arg1> [<arg2> [...]]]
extern const char* kMPVCommand_Run;
// subprocess
extern const char* kMPVCommand_Subprocess;
// quit [<code>]
extern const char* kMPVCommand_Quit;
// quit-watch-later [<code>]
extern const char* kMPVCommand_QuitWatchLater;
// sub-add <url> [<flags> [<title> [<lang>]]]
extern const char* kMPVCommand_SubAdd;
// sub-remove [<id>]
extern const char* kMPVCommand_SubRemove;
// sub-reload [<id>]
extern const char* kMPVCommand_SubReload;
// sub-step <skip> <flags>
extern const char* kMPVCommand_SubStep;
// sub-seek <skip> <flags>
extern const char* kMPVCommand_SubSeek;
// print-text <text>
extern const char* kMPVCommand_PrintText;
// show-text <text> [<duration>|-1 [<level>]]
extern const char* kMPVCommand_ShowText;
// expand-text <string>
extern const char* kMPVCommand_ExpandText;
// expand-path "<string>"
extern const char* kMPVCommand_ExpandPath;
// show-progress
extern const char* kMPVCommand_ShowProgress;
// write-watch-later-config
extern const char* kMPVCommand_WriteWatchLaterConfig;
// delete-watch-later-config [<filename>]
extern const char* kMPVCommand_DeleteWatchLaterConfig;
// stop [<flags>]
extern const char* kMPVCommand_Stop;
// mouse <x> <y> [<button> [<mode>]]
extern const char* kMPVCommand_Mouse;
// keypress <name>
extern const char* kMPVCommand_Keypress;
// keydown <name>
extern const char* kMPVCommand_Keydown;
// keyup [<name>]
extern const char* kMPVCommand_Keyup;
// keybind <name> <command>
extern const char* kMPVCommand_Keybind;
// audio-add <url> [<flags> [<title> [<lang>]]]
extern const char* kMPVCommand_AudioAdd;
// audio-remove [<id>]
extern const char* kMPVCommand_AudioRemove;
// audio-reload [<id>]
extern const char* kMPVCommand_AudioReload;
// video-add <url> [<flags> [<title> [<lang> [<albumart>]]]]
extern const char* kMPVCommand_VideoAdd;
// video-remove [<id>]
extern const char* kMPVCommand_VideoRemove;
// video-reload [<id>]
extern const char* kMPVCommand_VideoReload;
// rescan-external-files [<mode>]
extern const char* kMPVCommand_RescanExternalFiles;
// af <operation> <value>
extern const char* kMPVCommand_Af;
// vf <operation> <value>
extern const char* kMPVCommand_Vf;
// cycle-values [<"!reverse">] <property> <value1> [<value2> [...]]
extern const char* kMPVCommand_CycleValues;
// enable-section <name> [<flags>]
extern const char* kMPVCommand_EnableSection;
// disable-section <name>
extern const char* kMPVCommand_DisableSection;
// define-section <name> <contents> [<flags>]
extern const char* kMPVCommand_DefineSection;
// overlay-add <id> <x> <y> <file> <offset> <fmt> <w> <h> <stride>
extern const char* kMPVCommand_OverlayAdd;
// overlay-remove <id>
extern const char* kMPVCommand_OverlayRemove;
// osd-overlay
extern const char* kMPVCommand_OSDOverlay;
// script-message [<arg1> [<arg2> [...]]]
extern const char* kMPVCommand_ScriptMessage;
// script-message-to <target> [<arg1> [<arg2> [...]]]
extern const char* kMPVCommand_ScriptMessageTo;
// script-binding <name>
extern const char* kMPVCommand_ScriptBinding;
// ab-loop
extern const char* kMPVCommand_ABLoop;
// drop-buffers
extern const char* kMPVCommand_DropBuffers;
// screenshot-raw [<flags>]
extern const char* kMPVCommand_ScreenshotRaw;
// vf-command <label> <command> <argument>
extern const char* kMPVCommand_VfCommand;
// af-command <label> <command> <argument>
extern const char* kMPVCommand_AfCommand;
// apply-profile <name> [<mode>]
extern const char* kMPVCommand_ApplyProfile;
// load-script <filename>
extern const char* kMPVCommand_LoadScript;
// change-list <name> <operation> <value>
extern const char* kMPVCommand_ChangeList;
// dump-cache <start> <end> <filename>
extern const char* kMPVCommand_DumpCache;
// ab-loop-dump-cache <filename>
extern const char* kMPVCommand_ABLoopDumpCache;
// ab-loop-align-cache
extern const char* kMPVCommand_ABLoopAlignCache;

// none
extern const char* kMPVEvent_None;
// shutdown
extern const char* kMPVEvent_Shutdown;
// logMessage
extern const char* kMPVEvent_LogMessage;
// getPropertyReply
extern const char* kMPVEvent_GetPropertyReply;
// setPropertyReply
extern const char* kMPVEvent_SetPropertyReply;
// commandReply
extern const char* kMPVEvent_CommandReply;
// startFile
extern const char* kMPVEvent_StartFile;
// endFile
extern const char* kMPVEvent_EndFile;
// fileLoaded
extern const char* kMPVEvent_FileLoaded;
// tracksChanged
extern const char* kMPVEvent_TracksChanged;
// trackSwitched
extern const char* kMPVEvent_TrackSwitched;
// idle
extern const char* kMPVEvent_Idle;
// pause
extern const char* kMPVEvent_Pause;
// unpause
extern const char* kMPVEvent_Unpause;
// tick
extern const char* kMPVEvent_Tick;
// scriptInputDispatch
extern const char* kMPVEvent_ScriptInputDispatch;
// clientMessage
extern const char* kMPVEvent_ClientMessage;
// videoReconfig
extern const char* kMPVEvent_VideoReconfig;
// audioReconfig
extern const char* kMPVEvent_AudioReconfig;
// metadataUpdate
extern const char* kMPVEvent_MetadataUpdate;
// seek
extern const char* kMPVEvent_Seek;
// playbackRestart
extern const char* kMPVEvent_PlaybackRestart;
// propertyChange
extern const char* kMPVEvent_PropertyChange;
// chapterChange
extern const char* kMPVEvent_ChapterChange;
// queueOverflow
extern const char* kMPVEvent_QueueOverflow;

// on_load
extern const char* kMPVHook_OnLoad;
// on_load_fail
extern const char* kMPVHook_OnLoadFail;
// on_preloaded
extern const char* kMPVHook_OnPreloaded;
// on_unload
extern const char* kMPVHook_OnUnload;
