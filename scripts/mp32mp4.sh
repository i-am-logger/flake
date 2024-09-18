#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status

input_audio=$1
output_video=$2
background_image="background.jpg"
artist_name="Logger"
subtitle_file=$3  # Parameter for subtitle file
subtitle_type=$4  # Parameter for subtitle type (hard or soft)

# Check if input files exist
if [ ! -f "$input_audio" ]; then
    echo "Error: Input audio file '$input_audio' not found."
    exit 1
fi
if [ ! -f "$background_image" ]; then
    echo "Error: Background image file '$background_image' not found."
    exit 1
fi
if [ -n "$subtitle_file" ] && [ ! -f "$subtitle_file" ]; then
    echo "Error: Subtitle file '$subtitle_file' not found."
    exit 1
fi

# Define subtitle filters based on type
subtitle_filter=""
subtitle_map=""
if [ -n "$subtitle_file" ]; then
    if [ "$subtitle_type" = "hard" ]; then
        subtitle_filter=",subtitles=$subtitle_file:force_style='FontName=DejaVu Sans,FontSize=12'"
    elif [ "$subtitle_type" = "soft" ]; then
        subtitle_map="-map 2:s"
    else
        echo "Error: Invalid subtitle type. Use 'hard' or 'soft'."
        exit 1
    fi
fi

# Use nix-shell to enter the FFmpeg 7 Full environment
nix-shell -p ffmpeg_7-full --run "
echo 'Creating highly optimized audio visualization...'
ffmpeg -i \"$input_audio\" -i \"$background_image\" ${subtitle_file:+-i \"$subtitle_file\"} -filter_complex \"
    [0:a]showspectrum=
        size=320x60:
        mode=combined:
        slide=scroll:
        scale=log:
        color=intensity:
        fscale=lin:
        fps=5,
    format=rgba,colorkey=0x000000:0.1:0.5[spectrum];
    [1:v]scale=320:180,format=yuv420p[bg];
    [bg][spectrum]overlay=(W-w)/2:H-h-5[combined];
    [combined]drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf:
        fontsize=12:
        fontcolor=white:
        box=1:
        boxcolor=black@0.5:
        boxborderw=1:
        x=(w-text_w)/2:
        y=H-th-5:
        text='$artist_name'[withtext];
    [withtext]eq=brightness=0.1:contrast=1.1:saturation=0.8,
    noise=alls=20:allf=t,
    format=yuv420p
    $subtitle_filter
[out]\" -map '[out]' -map 0:a $subtitle_map -c:v libx264 -preset faster -crf 32 -c:a aac -b:a 32k -ar 22050 -ac 1 -shortest -movflags +faststart -r 5 \"$output_video\"
echo 'Video creation complete: $output_video'
"

# Check if the conversion was successful
if [ -f "$output_video" ]; then
    echo "Conversion successful! Output file: $output_video"
    echo "File size: $(du -h "$output_video" | cut -f1)"
else
    echo "Conversion failed. Please check the error messages above."
fi
