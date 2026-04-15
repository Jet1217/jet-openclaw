---
name: ffmpeg-edit
description: Master video editing and assembly using ffmpeg. Supports concatenation, trim/cut, audio merge, audio+video merge, subtitles (SRT/ASS), bilingual subtitles, transitions (xfade), animated text effects, color grading, watermarks, speed ramp, and platform export. All operations run locally via the ffmpeg CLI.
---

# ffmpeg-edit — Video Editing Skill

All commands run in the local shell. Always verify ffmpeg is available first.

```bash
which ffmpeg && ffmpeg -version | head -1
```

---

## Operation 1 — Concatenate Clips

### Method A: Stream copy (fast — clips must match codec/resolution/fps)

```bash
cat > /tmp/concat-list.txt << 'EOF'
file '/data/projects/<slug>/clips/clip-01.mp4'
file '/data/projects/<slug>/clips/clip-02.mp4'
file '/data/projects/<slug>/clips/clip-03.mp4'
EOF

ffmpeg -f concat -safe 0 -i /tmp/concat-list.txt \
  -c copy \
  /data/projects/<slug>/output/assembled.mp4
```

### Method B: Re-encode (safe for mixed sources)

```bash
ffmpeg \
  -i /data/projects/<slug>/clips/clip-01.mp4 \
  -i /data/projects/<slug>/clips/clip-02.mp4 \
  -i /data/projects/<slug>/clips/clip-03.mp4 \
  -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  /data/projects/<slug>/output/assembled.mp4
```

---

## Operation 2 — Trim / Cut a Segment

```bash
# Extract: start at 5s, take 10 seconds
ffmpeg -i input.mp4 \
  -ss 00:00:05 -t 00:00:10 \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  output-trimmed.mp4
```

### Remove a middle section (cut out 5s–15s)

```bash
ffmpeg -i input.mp4 -ss 0 -t 5 -c copy /tmp/part1.mp4
ffmpeg -i input.mp4 -ss 15 -c copy /tmp/part2.mp4

cat > /tmp/cut-list.txt << 'EOF'
file '/tmp/part1.mp4'
file '/tmp/part2.mp4'
EOF
ffmpeg -f concat -safe 0 -i /tmp/cut-list.txt -c copy output-cut.mp4
```

---

## Operation 3 — Merge Audio Tracks (Music + Video)

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

## Operation 4 — Audio/Video Merge (separate audio + video files)

Combine a video file (no audio or muted) with a separate audio file:

```bash
# Merge video track from video.mp4 with audio from audio.mp3
ffmpeg -i video.mp4 -i audio.mp3 \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 192k \
  -shortest \
  output-merged.mp4
```

### Video-only clip + audio-only clip (both as .mp4)

```bash
ffmpeg -i video-only.mp4 -i audio-only.mp4 \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 192k \
  -shortest \
  output-merged.mp4
```

---

## Operation 5 — Audio Ducking (Music Under Voiceover)

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]volume='if(between(t,0,30),0.1,0.8)':eval=frame[music];
     [0:a][music]amix=inputs=2:duration=first[outa]" \
  -map 0:v -map "[outa]" \
  -c:v copy -c:a aac -b:a 192k \
  output-ducked.mp4
```

---

## Operation 6 — Speed Ramp

```bash
# 2x speed
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" \
  -map "[v]" -map "[a]" \
  output-2x.mp4

# 0.5x slow motion
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" \
  -map "[v]" -map "[a]" \
  output-slow.mp4
```

---

## Operation 7 — Subtitles (SRT Burn-in)

Hardcode subtitles from an `.srt` file into the video:

```bash
ffmpeg -i input.mp4 \
  -vf "subtitles=subtitles.srt:force_style='FontName=Arial,FontSize=22,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Alignment=2'" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-subtitled.mp4
```

**Alignment values:** 2 = bottom center (default), 8 = top center, 5 = middle center

### Soft subtitles (selectable, not burned in — MP4 only)

```bash
ffmpeg -i input.mp4 -i subtitles.srt \
  -map 0 -map 1 \
  -c:v copy -c:a copy -c:s mov_text \
  output-soft-subs.mp4
```

---

## Operation 8 — Subtitles (ASS — Styled)

ASS format gives full control over font, color, shadow, border, and per-line positioning.

### Step 1: Create an ASS subtitle file

```bash
cat > /tmp/styled.ass << 'EOF'
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name,Fontname,Fontsize,PrimaryColour,SecondaryColour,OutlineColour,BackColour,Bold,Italic,Underline,StrikeOut,ScaleX,ScaleY,Spacing,Angle,BorderStyle,Outline,Shadow,Alignment,MarginL,MarginR,MarginV,Encoding
Style: Default,Arial,52,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,60,60,40,1

[Events]
Format: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,This is a styled subtitle
Dialogue: 0,0:00:05.00,0:00:08.00,Default,,0,0,0,,Second line here
EOF

ffmpeg -i input.mp4 \
  -vf "ass=/tmp/styled.ass" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-ass.mp4
```

---

## Operation 9 — Bilingual Subtitles (e.g. Chinese + English)

Two-line bilingual subtitles using ASS with two distinct styles. Primary language larger at bottom, secondary language smaller just above.

### Step 1: Create bilingual ASS file

```bash
cat > /tmp/bilingual.ass << 'EOF'
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name,Fontname,Fontsize,PrimaryColour,SecondaryColour,OutlineColour,BackColour,Bold,Italic,Underline,StrikeOut,ScaleX,ScaleY,Spacing,Angle,BorderStyle,Outline,Shadow,Alignment,MarginL,MarginR,MarginV,Encoding
Style: Chinese,PingFang SC,52,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,60,60,40,1
Style: English,Arial,36,&H00E0E0E0,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,1,2,60,60,100,1

[Events]
Format: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text
Dialogue: 0,0:00:01.00,0:00:04.00,Chinese,,0,0,0,,你好，欢迎来到我们的频道
Dialogue: 0,0:00:01.00,0:00:04.00,English,,0,0,0,,Hello, welcome to our channel
Dialogue: 0,0:00:05.00,0:00:09.00,Chinese,,0,0,0,,今天我们来聊聊视频剪辑
Dialogue: 0,0:00:05.00,0:00:09.00,English,,0,0,0,,Today we talk about video editing
EOF
```

**MarginV controls vertical offset:** Chinese at 40px from bottom, English at 100px (sits just above Chinese).

### Step 2: Burn in

```bash
ffmpeg -i input.mp4 \
  -vf "ass=/tmp/bilingual.ass" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-bilingual.mp4
```

---

## Operation 10 — Transitions Between Clips (xfade)

`xfade` creates frame-blended transitions between two clips. The `offset` must be set to `(duration_of_clip1 - transition_duration)`.

### Supported transition types

`fade` `dissolve` `wipeleft` `wiperight` `wipeup` `wipedown` `slideleft` `slideright` `slideup` `slidedown` `circlecrop` `rectcrop` `distance` `fadeblack` `fadewhite` `radial` `smoothleft` `smoothright` `smoothup` `smoothdown` `zoomin` `pixelize` `hblur`

### Two clips with cross-dissolve (0.5s transition, clip1 is 5s)

```bash
ffmpeg -i clip-01.mp4 -i clip-02.mp4 \
  -filter_complex \
    "[0:v][1:v]xfade=transition=dissolve:duration=0.5:offset=4.5[outv];
     [0:a][1:a]acrossfade=d=0.5[outa]" \
  -map "[outv]" -map "[outa]" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  output-dissolve.mp4
```

### Three clips with different transitions (clip1=5s, clip2=4s, all 0.5s transitions)

```bash
ffmpeg -i clip-01.mp4 -i clip-02.mp4 -i clip-03.mp4 \
  -filter_complex \
    "[0:v][1:v]xfade=transition=wipeleft:duration=0.5:offset=4.5[v01];
     [v01][2:v]xfade=transition=fadeblack:duration=0.5:offset=8.0[outv];
     [0:a][1:a]acrossfade=d=0.5[a01];
     [a01][2:a]acrossfade=d=0.5[outa]" \
  -map "[outv]" -map "[outa]" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 192k \
  output-transitions.mp4
```

### Fade in from black at start / fade to black at end

```bash
ffmpeg -i input.mp4 \
  -vf "fade=t=in:st=0:d=1,fade=t=out:st=9:d=1" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-faded.mp4
```

---

## Operation 11 — Text Effects

### Animated title: fade in + hold + fade out (centered)

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Your Title':
       fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:
       fontsize=80:fontcolor=white:
       x=(w-text_w)/2:y=(h-text_h)/2:
       alpha='if(lt(t,1),t,if(lt(t,4),1,if(lt(t,5),5-t,0)))':
       shadowcolor=black@0.8:shadowx=3:shadowy=3" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-animated-title.mp4
```

### Typewriter effect (text reveals character by character)

```bash
# Reveal text one character at a time, 5 chars/sec, starting at t=1s
# "Hello World" = 11 chars, full reveal at t=3.2s
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Hello World':
       fontsize=60:fontcolor=white:
       x=(w-text_w)/2:y=h-150:
       shadowcolor=black:shadowx=2:shadowy=2:
       textfile_width=0:
       expansion=normal:
       text_shaping=1" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-typewriter.mp4
```

**True typewriter with progressive reveal using `nb_chars`:**

```bash
# Each second reveals 5 more characters (text must be stored in a file)
echo "Hello World" > /tmp/title.txt

ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=/tmp/title.txt:
       fontsize=60:fontcolor=white:
       x=(w-text_w)/2:y=h-150:
       nb_chars='min(floor((t-1)*5), 11)':
       shadowcolor=black:shadowx=2:shadowy=2" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-typewriter.mp4
```

### Slide-in lower third (animates from left)

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Speaker Name | Title':
       fontsize=40:fontcolor=white:
       x='if(lt(t,1),(-text_w + (t * text_w)),60)':y=h-120:
       enable='between(t,1,6)':
       box=1:boxcolor=black@0.6:boxborderw=15:
       shadowcolor=black@0.5:shadowx=2:shadowy=2" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-lower-third.mp4
```

### Kinetic text: zoom pulse on beat

```bash
# Text scales from 0.5x to 1.0x over 0.3s, triggered at t=1s
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BIG MOMENT':
       fontsize='60 * (0.5 + 0.5 * min((t-1)/0.3, 1))':
       fontcolor=white:
       x=(w-text_w)/2:y=(h-text_h)/2:
       enable='gte(t,1)':
       shadowcolor=black:shadowx=4:shadowy=4" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-kinetic.mp4
```

### Scrolling credits (bottom to top)

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=/tmp/credits.txt:
       fontsize=36:fontcolor=white:
       x=(w-text_w)/2:
       y=h-60*(t-5):
       enable='gte(t,5)':
       shadowcolor=black:shadowx=2:shadowy=2" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-credits.mp4
```

---

## Operation 12 — Watermark / Logo Overlay

```bash
# Bottom-right corner, 10px padding, at 70% opacity
ffmpeg -i input.mp4 -i logo.png \
  -filter_complex \
    "[1:v]scale=120:-1[logo];
     [0:v][logo]overlay=W-w-10:H-h-10:format=auto,format=yuv420p" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-watermarked.mp4
```

---

## Operation 13 — Color Grading

### Brightness / Contrast / Saturation

```bash
ffmpeg -i input.mp4 \
  -vf "eq=brightness=0.05:contrast=1.1:saturation=1.2:gamma=1.0" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-graded.mp4
```

### Cinematic look (slight desaturate + lift shadows)

```bash
ffmpeg -i input.mp4 \
  -vf "eq=saturation=0.85:contrast=1.05,curves=r='0/10 255/245':g='0/5 255/250':b='0/20 255/240'" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a copy \
  output-cinematic.mp4
```

---

## Operation 14 — Platform Export

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

## Operation 15 — Download Clips

```bash
curl -L -o /data/projects/<slug>/clips/clip-01.mp4 "https://..."

# Verify
ffprobe -v quiet -print_format json -show_format -show_streams \
  /data/projects/<slug>/clips/clip-01.mp4 \
  | jq '{duration: .format.duration, size: .format.size, streams: [.streams[] | {codec: .codec_name, type: .codec_type, width: .width, height: .height, fps: .r_frame_rate}]}'
```

---

## Operation 16 — Add Silent Audio to Video-Only Clip

```bash
ffmpeg -i video-no-audio.mp4 \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -c:v copy -c:a aac -b:a 192k \
  -shortest \
  video-with-silent-audio.mp4
```

---

## Error Reference

| Error                                      | Cause                          | Fix                                                |
| ------------------------------------------ | ------------------------------ | -------------------------------------------------- |
| `Invalid data found when processing input` | Corrupt or incomplete download | Re-download the clip                               |
| `Encoder not found: libx264`               | ffmpeg built without x264      | Use `-c:v copy` or install full ffmpeg             |
| `No such file or directory`                | Wrong path                     | Check file path with `ls`                          |
| `Output file is empty`                     | Filter graph error             | Check filter_complex syntax                        |
| `Audio and video streams not found`        | Clip has no audio              | Add `-an` or add silent audio track                |
| `Fontconfig error`                         | Font not found for drawtext    | Use `fontfile=` with absolute path or install font |
| `xfade offset` error                       | Offset exceeds clip duration   | Set offset = clip1_duration - transition_duration  |
| `ASS subtitle not rendering`               | Font missing for CJK chars     | Install `fonts-noto-cjk` or use fontdir parameter  |
