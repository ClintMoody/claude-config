Extract frames from a video or animated GIF so you can visually analyze them.

The user wants you to view: $ARGUMENTS

## Instructions

1. Parse the arguments. Expected format: `<file_path> [description/question]`
   - The file path is the first argument (required)
   - Everything after is an optional description or question about the video

2. Determine the output directory:
   - Use the scratchpad directory for temp files
   - Create a subfolder named `video-frames/` inside it

3. First, probe the file to get duration and frame count:
   ```bash
   ffprobe -v error -select_streams v:0 -show_entries stream=duration,nb_frames,r_frame_rate,width,height -show_entries format=duration -of csv=p=0 "<file_path>"
   ```

4. Extract frames using ffmpeg with these rules:
   - For GIFs or videos under 5 seconds: extract ALL frames (up to 20 max)
     ```bash
     ffmpeg -i "<file>" -vf "select=not(mod(n\,<skip>))" -vsync vfr -frames:v 20 "<outdir>/frame_%03d.png"
     ```
   - For videos 5-30 seconds: extract 1 frame per second (max 20)
     ```bash
     ffmpeg -i "<file>" -vf "fps=1" -frames:v 20 "<outdir>/frame_%03d.png"
     ```
   - For videos over 30 seconds: extract evenly spaced frames (max 15)
     ```bash
     ffmpeg -i "<file>" -vf "fps=<calculated>" -frames:v 15 "<outdir>/frame_%03d.png"
     ```
   - Always use `-y` to overwrite existing files

5. After extraction, use the Read tool to view EACH extracted frame image file. View them all - they are images and you can see them.

6. After viewing all frames, provide analysis:
   - Describe what you see happening across the frames (the visual sequence/animation)
   - If the user asked a question, answer it based on what you observe
   - If this appears to be a UI bug report, describe the visual issue you can identify
   - Reference specific frame numbers when describing events

7. If the file doesn't exist or ffmpeg fails, report the error clearly.
