//
//  MPVConstants.m
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

// Version properties
const char* const kMPVProperty_ffmpeg_version =			"ffmpeg-version";
const char* const kMPVProperty_libass_version =			"libass-version";
const char* const kMPVProperty_mpv_version =			"mpv-version";

// Read-only properties
const char* const kMPVProperty_audio_bitrate =			"audio-bitrate";
const char* const kMPVProperty_audio_codec =			"audio-codec";
const char* const kMPVProperty_audio_codec_name =		"audio-codec-name";
const char* const kMPVProperty_dheight =				"dheight";
const char* const kMPVProperty_duration =				"duration";
const char* const kMPVProperty_dwidth =					"dwidth";
const char* const kMPVProperty_estimated_frame_count =	"estimated-frame-count";
const char* const kMPVProperty_estimated_frame_number =	"estimated-frame-number";
const char* const kMPVProperty_file_format =			"file-format";
const char* const kMPVProperty_file_size =				"file-size";
const char* const kMPVProperty_filename =				"filename";
const char* const kMPVProperty_filename_no_ext =		"filename/no-ext";
const char* const kMPVProperty_height =					"height";
const char* const kMPVProperty_media_title =			"media-title";
const char* const kMPVProperty_path =					"path";
const char* const kMPVProperty_pause =					"pause";
const char* const kMPVProperty_playlist_count =			"playlist-count";
const char* const kMPVProperty_playlist_playing_pos =	"playlist-playing-pos";
const char* const kMPVProperty_sub_bitrate =			"sub-bitrate";
const char* const kMPVProperty_time_remaining =			"time-remaining";
const char* const kMPVProperty_video_bitrate =			"video-bitrate";
const char* const kMPVProperty_video_codec =			"video-codec";
const char* const kMPVProperty_video_format =			"video-format";
const char* const kMPVProperty_video_params_aspect =	"video-params/aspect";
const char* const kMPVProperty_width =					"width";

// Read-write properties
const char* const kMPVProperty_ao_mute =				"ao-mute";
const char* const kMPVProperty_ao_volume =				"ao-volume";
const char* const kMPVProperty_percent_pos =			"percent-pos";
const char* const kMPVProperty_playback_time =			"playback-time";
const char* const kMPVProperty_playlist_pos =			"playlist-pos";
const char* const kMPVProperty_time_pos =				"time-pos";
const char* const kMPVProperty_sid =					"sid";

// Property keys
const char* const kMPVPropertyKey_name =				"name";
const char* const kMPVPropertyKey_data =				"data";
const char* const kMPVPropertyKey_id =					"id";
const char* const kMPVPropertyKey_no =					"no";

// Config options
const char* const kMPVOption_hwdec =					"hwdec";
const char* const kMPVOption_vo =						"vo";

// Config option params
const char* const kMPVOptionParam_libmpv =				"libmpv";
const char* const kMPVOptionParam_videotoolbox =		"videotoolbox";

// Commands
const char* const kMPVCommand_loadfile =				"loadfile";
const char* const kMPVCommand_quit =					"quit";
const char* const kMPVCommand_playlist_play_index =		"playlist-play-index";
const char* const kMPVCommand_frame_step =				"frame-step";
const char* const kMPVCommand_frame_back_step =			"frame-back-step";
const char* const kMPVCommand_seek =					"seek";

// Command params
const char* const kMPVCommandParam_relative =			"relative";
const char* const kMPVCommandParam_absolute =			"absolute";
const char* const kMPVCommandParam_absolute_percent =	"absolute-percent";
const char* const kMPVCommandParam_keyframes =			"keyframes";
const char* const kMPVCommandParam_exact =				"exact";
const char* const kMPVCommandParam_replace =			"replace";
