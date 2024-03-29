//
//  MPVConstants.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

// Version properties
extern const char* const kMPVProperty_ffmpeg_version;
extern const char* const kMPVProperty_libass_version;
extern const char* const kMPVProperty_mpv_version;

// Read-only properties
extern const char* const kMPVProperty_audio_bitrate;
extern const char* const kMPVProperty_audio_codec;
extern const char* const kMPVProperty_audio_codec_name;
extern const char* const kMPVProperty_dheight;
extern const char* const kMPVProperty_duration;
extern const char* const kMPVProperty_dwidth;
extern const char* const kMPVProperty_estimated_frame_count;
extern const char* const kMPVProperty_estimated_frame_number;
extern const char* const kMPVProperty_file_format;
extern const char* const kMPVProperty_file_size;
extern const char* const kMPVProperty_filename;
extern const char* const kMPVProperty_filename_no_ext;
extern const char* const kMPVProperty_height;
extern const char* const kMPVProperty_media_title;
extern const char* const kMPVProperty_path;
extern const char* const kMPVProperty_pause;
extern const char* const kMPVProperty_playlist_count;
extern const char* const kMPVProperty_playlist_playing_pos;
extern const char* const kMPVProperty_sub_bitrate;
extern const char* const kMPVProperty_time_remaining;
extern const char* const kMPVProperty_video_bitrate;
extern const char* const kMPVProperty_video_codec;
extern const char* const kMPVProperty_video_format;
extern const char* const kMPVProperty_video_params_aspect;
extern const char* const kMPVProperty_width;

// Read-write properties
extern const char* const kMPVProperty_ao_mute;
extern const char* const kMPVProperty_ao_volume;
extern const char* const kMPVProperty_percent_pos;
extern const char* const kMPVProperty_playback_time;
extern const char* const kMPVProperty_playlist_pos;
extern const char* const kMPVProperty_time_pos;
extern const char* const kMPVProperty_sid;

// Property keys
extern const char* const kMPVPropertyKey_name;
extern const char* const kMPVPropertyKey_data;
extern const char* const kMPVPropertyKey_id;
extern const char* const kMPVPropertyKey_no;

// Config options
extern const char* const kMPVOption_hwdec;
extern const char* const kMPVOption_vo;

// Config option params
extern const char* const kMPVOptionParam_libmpv;
extern const char* const kMPVOptionParam_videotoolbox;

// Commands
extern const char* const kMPVCommand_loadfile;
extern const char* const kMPVCommand_quit;
extern const char* const kMPVCommand_playlist_play_index;
extern const char* const kMPVCommand_frame_step;
extern const char* const kMPVCommand_frame_back_step;
extern const char* const kMPVCommand_seek;

// Command params
extern const char* const kMPVCommandParam_relative;
extern const char* const kMPVCommandParam_absolute;
extern const char* const kMPVCommandParam_absolute_percent;
extern const char* const kMPVCommandParam_keyframes;
extern const char* const kMPVCommandParam_exact;
extern const char* const kMPVCommandParam_replace;
