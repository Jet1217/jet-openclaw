---
name: ffmpeg-edit
description: Video editing and assembly using ffmpeg. Use this skill to concatenate video clips, trim/cut segments, merge audio tracks (music + voiceover), apply audio ducking, speed ramp, add text overlays, and convert video formats. All operations run locally via the ffmpeg CLI.
---

# ffmpeg-edit — Video Editing Skill

This skill provides ffmpeg-based video editing operations. All commands run in the local shell.

**Prerequisite:** ffmpeg must be installed in the sandbox.

```bash
which ffmpeg || echo "ffmpeg not found — install required"
```

---

## Operation 1 — Concatenate Clips

Joins multiple video clips in sequence. All clips must have the same codec, resolution, and frame rate for a clean concat. If they differ, use the re-encode method.

### Method A: Stream copy (fast, no re-encode — clips must match specs)

```bash
# 1. Create a file list
cat > /tmp/concat-list.txt << 'EOF'
file '/data/workspace-video-editor/clips/clip-01.mp4'
file '/data/workspace-video-editor/clips/clip-02.mp4'
file '/data/workspace-video-editor/clips/clip-03.mp4'
EOF

# 2. Concatenate
ffmpeg -f concat -safe 0 -i /tmp/concat-list.txt \
  -c copy \
  /data/workspace-video-editor/output/assembled.mp4
```

### Method B: Re-encode (safe for mixed sources)

```bash
ffmpeg \
  -i /data/workspace-video-editor/clips/clip-01.mp4 \
  -i /data/workspace-video-editor/clips/clip-02.mp4 \
  -i /data/workspace-video-editor/clips/clip-03.mp4 \
  -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  /data/workspace-video-editor/output/assembled.mp4
```

---

## Operation 2 — Trim / Cut a Segment

Extract a portion of a video by start time and duration.

```bash
# Trim: start at 5s, take 10 seconds
ffmpeg -i input.mp4 \
  -ss 00:00:05 -t 00:00:10 \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  output-trimmed.mp4
```

To cut OUT a segment (remove middle section), trim into two parts then concatenate:

```bash
# Part 1: 0s to 5s
ffmpeg -i input.mp4 -ss 0 -t 5 -c copy /tmp/part1.mp4

# Part 2: 15s to end
ffmpeg -i input.mp4 -ss 15 -c copy /tmp/part2.mp4

# Concat parts
cat > /tmp/cut-list.txt << 'EOF'
file '/tmp/part1.mp4'
file '/tmp/part2.mp4'
EOF
ffmpeg -f concat -safe 0 -i /tmp/cut-list.txt -c copy output-cut.mp4
```

---

## Operation 3 — Merge Audio Tracks (Music + Video)

Replace or mix the video's audio with a music track.

### Replace audio entirely

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k \
  -shortest \
  output-with-music.mp4
```

### Mix original audio + background music (music at -20dB)

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]volume=0.15[music];[0:a][music]amix=inputs=2:duration=first[outa]" \
  -map 0:v -map "[outa]" \
  -c:v copy -c:a aac -b:a 192k \
  output-mixed.mp4
```

---

## Operation 4 — Audio Ducking (Music Under Voiceover)

Automatically lower music volume when voiceover is present.

```bash
# video.mp4 has voiceover on track 0:a
# music.mp3 is background music
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]volume=0.8[music_full];
     [0:a]asplit=2[vo][vo_detect];
     [vo_detect]silencedetect=noise=-30dB:duration=0.3[silence];
     [music_full]sidechaincompress=threshold=0.02:ratio=4:attack=200:release=1000[music_ducked];
     [vo][music_ducked]amix=inputs=2:duration=first[outa]" \
  -map 0:v -map "[outa]" \
  -c:v copy -c:a aac -b:a 192k \
  output-ducked.mp4
```

**Simpler approach** (manual volume envelope — more reliable):

```bash
# Lower music to 10% during voiceover sections (0s–30s)
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]volume='if(between(t,0,30),0.1,0.8)':eval=frame[music];
     [0:a][music]amix=inputs=2:duration=first[outa]" \
  -map 0:v -map "[outa]" \
  -c:v copy -c:a aac -b:a 192k \
  output-ducked.mp4
```

---

## Operation 5 — Speed Ramp

Change playback speed of a clip.

```bash
# 2x speed (setpts=0.5*PTS speeds up video; atempo=2.0 speeds up audio)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" \
  -map "[v]" -map "[a]" \
  output-2x.mp4

# 0.5x slow motion (setpts=2*PTS; atempo=0.5)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" \
  -map "[v]" -map "[a]" \
  output-slow.mp4
```

---

## Operation 6 — Add Text Overlay

Burn text onto the video (captions, titles, lower thirds).

```bash
# Simple centered title at top, white text, 3s duration
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Your Title Here':
       fontsize=60:fontcolor=white:
       x=(w-text_w)/2:y=80:
       enable='between(t,0,3)':
       shadowcolor=black:shadowx=2:shadowy=2" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-titled.mp4
```

```bash
# Lower third (bottom left), appears at 5s for 4 seconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Speaker Name':
       fontsize=40:fontcolor=white:
       x=60:y=h-120:
       enable='between(t,5,9)':
       box=1:boxcolor=black@0.5:boxborderw=10" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-lower-third.mp4
```

---

## Operation 7 — Format Conversion & Platform Export

### TikTok / Reels (9:16, 1080×1920)

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,
       pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx264 -crf 23 -preset fast -b:v 8M \
  -c:a aac -b:a 192k -ar 44100 \
  -r 30 \
  output-tiktok.mp4
```

### YouTube (16:9, 1920×1080)

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,
       pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx264 -crf 23 -preset fast -b:v 8M \
  -c:a aac -b:a 192k -ar 44100 \
  -r 30 \
  output-youtube.mp4
```

---

## Operation 8 — Download Video from URL

Before editing, download clips from Chraft/CDN URLs:

```bash
# Using curl
curl -L -o /data/workspace-video-editor/clips/clip-01.mp4 "https://..."

# Using wget
wget -O /data/workspace-video-editor/clips/clip-01.mp4 "https://..."
```

Verify the download:

```bash
ffprobe -v quiet -print_format json -show_format -show_streams \
  /data/workspace-video-editor/clips/clip-01.mp4
```

---

## Utility — Get Video Info

```bash
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4 \
  | jq '{duration: .format.duration, size: .format.size, streams: [.streams[] | {codec: .codec_name, type: .codec_type, width: .width, height: .height, fps: .r_frame_rate}]}'
```

---

## Error Reference

| Error                                      | Cause                          | Fix                                               |
| ------------------------------------------ | ------------------------------ | ------------------------------------------------- |
| `Invalid data found when processing input` | Corrupt or incomplete download | Re-download the clip                              |
| `Encoder not found: libx264`               | ffmpeg built without x264      | Use `-c:v copy` or install full ffmpeg            |
| `No such file or directory`                | Wrong path                     | Check file path with `ls`                         |
| `Output file is empty`                     | Filter graph error             | Check filter_complex syntax                       |
| `Audio and video streams not found`        | Clip has no audio              | Add `-an` to skip audio or add silent audio track |

### Add silent audio to a video-only clip

```bash
ffmpeg -i video-no-audio.mp4 \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -c:v copy -c:a aac -b:a 192k \
  -shortest \
  video-with-silent-audio.mp4
```
