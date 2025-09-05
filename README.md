Glitch’s General File Hub — README
==================================

This is a portable Windows batch tool that can:
• Download YouTube links (single videos or full playlists) to MP4 / MP3 (yt-dlp + FFmpeg)
• Compress a video to a target file size (2-pass H.264)
• Convert audio/video file extensions
• Convert images (single file or an entire folder)

Everything installs locally into a “tools” folder on first run. No admin rights required.


0) Requirements
---------------
• Windows 10/11
• Internet access on first run (to auto-download yt-dlp and FFmpeg)
• Disk space for downloads and conversions

Folder layout (created automatically):
  Glitch_File_Hub.bat
  tools\
  tools\_tmp\
  downloads\
  compressed\
  converted\
  converted\images\


1) First Run
------------
1. Double-click **Glitch_File_Hub.bat**.
2. The script creates folders and downloads:
   • tools\yt-dlp.exe
   • tools\ffmpeg.exe and tools\ffprobe.exe
3. If downloading fails (offline/firewall), manually place those EXEs into **tools** and run again.

Tip: If Windows SmartScreen warns about an unknown publisher, click **More info → Run anyway** (only if you trust this tool).


2) YouTube Cookies (one-time setup)
-----------------------------------
The Link Converter uses **cookies.txt** so yt-dlp can access age-gated or logged-in videos.

Steps:
1. Open your browser and log in to YouTube.
2. Install any “cookies.txt” exporter extension from your browser’s store.
3. Export cookies **for youtube.com** to this exact file path:
     tools\cookies.txt
4. Run the batch again. The menu will show “Cookies: tools\cookies.txt”.

Note: If you later get login-related errors or 403s, re-export a fresh cookies.txt.


3) Using the Menus (global)
---------------------------
• Type **M** or **B** at almost any prompt to return to the main menu.
• The tool validates the YouTube URL (must start with http/https). If you paste something else, it will ask again.


4) Link Converter (YouTube)
---------------------------
Menu path: **1) Link Converter**

A) Choose format
   1) MP4 (video with AAC audio)
   2) MP3 (audio only)
   3) MP4 (no audio – silent)

B) Paste a URL
   • Accepts single videos or playlist URLs.
   • After the URL, you’ll be asked:
       “Download FULL playlist if URL is a playlist? (Y/N)”
     – **N** (default): download only the single video
     – **Y**: download the whole playlist into a subfolder and prefix files with the index

C) Where files go
   • Downloads are saved to the **downloads** folder.
   • For playlists, files go to **downloads\<Playlist Title>\**

D) Update yt-dlp
   • Menu option 4 updates yt-dlp in place.

Troubleshooting:
   • “not a valid URL” — paste a full http/https link
   • Age-gated/private videos — make sure cookies.txt is fresh and from the account with access
   • 403/410/429 or login errors — re-export cookies.txt and try again
   • “HTTP Error 416” — a transient CDN/range issue; trying again usually works


5) Media Compressor (Target Size)
---------------------------------
Menu path: **2) Media Compressor (manual duration)**

• Select a video file.
• Enter a **target size in MB** (e.g., 12).
• Enter the video duration (seconds OR mm:ss OR hh:mm:ss).
• The tool computes a bitrate and does **2-pass H.264** with AAC audio.

Output file goes to **compressed** and is named `<OriginalName>_<TargetMB>MB.mp4`.

Tips:
• If the output is significantly smaller than the target, the content may be static/low-detail; raise audio bitrate or target size if needed.
• If you’re unsure of duration, right-click the video → Properties → Details.


6) File Extension Converter
---------------------------
Menu path: **3) File Extension Converter**

Pick a source file and convert to:
• MP4  (H.264 + AAC)   [video]
• WEBM (VP9  + Opus)   [video]
• MP3  (libmp3lame)    [audio]
• WAV  (PCM s16le)     [audio]
• M4A  (AAC)           [audio]

Converted files are placed in **converted**.


7) Image Converter
------------------
Menu path: **4) Image Converter**

• Input can be a single image or a folder with images.
• Choose output format: JPG (lossy), PNG (lossless), WEBP (lossy).
• Optional: max width (px) to scale down; height auto-fits.
• Optional: quality 1–100 (default 85 for JPG, 80 for WEBP).

Converted images go to **converted\images**.

Note: JPG quality is mapped internally to encoder settings; higher number ≈ higher quality/larger file.


8) Common Problems & Fixes
--------------------------
• Pasted “@echo off” or other text into the URL prompt
  – Cause: non-URL on clipboard. Fix: paste a full http/https link.
• “cookies.txt not found”
  – Use the Cookies helper or export the file manually to: tools\cookies.txt
• Firewall blocks downloads of tools
  – Manually download yt-dlp.exe, ffmpeg.exe, ffprobe.exe and place them into tools\
• “FFmpeg not found”
  – The script tries three mirrors + built-in extraction. If all fail, download a Windows FFmpeg build and place ffmpeg.exe & ffprobe.exe into tools\
• Playlist titles with unusual characters
  – Windows will sanitize names; if a folder can’t be created, yt-dlp will fallback to a safe name.


9) Privacy & Notes
------------------
• Your cookies stay on your machine (tools\cookies.txt). They are only passed to yt-dlp locally.
• This tool is for personal use. Respect YouTube’s Terms of Service and local laws.
• No personal data is transmitted by the script itself; yt-dlp/ffmpeg connect only to the media/CDN hosts you request.


10) Quick FAQ
-------------
Q: Where are the downloaded files?
A: In the **downloads** folder (playlists in a subfolder named after the playlist).

Q: How do I go back to the main menu?
A: Type **M** or **B** at any prompt.

Q: Can I change audio quality for MP3?
A: The default is VBR q=0 (high quality). If you want custom presets, ask and we can extend the menu.

Q: How do I update yt-dlp later?
A: Inside Link Converter, choose **Update yt-dlp**.


Credits & Licenses
------------------
Publisher
• Glitch - glitch0015@gmail.com

Contributors
• Assistant: GPT-5 Thinking (OpenAI) — script design, code, documentation.

Open‑source tools used
• yt-dlp — https://github.com/yt-dlp/yt-dlp — GPLv3
• FFmpeg — https://ffmpeg.org/ — GPL/LGPL (depending on build components)
• Windows built‑ins — PowerShell, curl, certutil, tar — used for downloading and extracting tools

Icon designer
• DJWGames - djwgames2006@gmail.com

Licensing notes
• This batch script is yours to publish and distribute. yt-dlp and FFmpeg are separate projects with their own licenses. When distributing binaries, follow their license terms.
