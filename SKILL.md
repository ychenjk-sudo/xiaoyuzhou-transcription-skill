---
name: xiaoyuzhou-transcription
description: "Transcribe 小宇宙 (Xiaoyuzhou) podcast episodes to text with structured summaries. Extracts audio from a 小宇宙 link, runs Qwen ASR transcription, formats a speaker-segmented verbatim transcript, and generates key-point summaries and Q&A. Use when a user shares a 小宇宙 podcast link, requests 播客转录 (podcast transcription), 音频转文字 (audio-to-text), 逐字稿 (verbatim transcript), or 播客内容总结 (podcast content summary)."
user-invocable: true
triggers:
  - "小宇宙"
  - "播客转录"
  - "音频转文字"
  - "逐字稿"
  - "播客内容总结"
  - "xiaoyuzhou"
  - "podcast transcription"
---

# 小宇宙播客转录与总结

Transcribe 小宇宙 podcast episodes into structured Markdown: speaker-segmented verbatim transcript with timestamps, 5–8 key-point summaries grouped by theme, and 8–10 Q&A pairs covering core content.

## Prerequisites

- **Environment variable**: `QWEN_API_KEY` — 阿里云 DashScope API Key (required)
- **Dependencies**: `curl`, `jq`, `python3`

## Workflow

### Step 1: Transcribe audio

```bash
./scripts/transcribe.sh "https://www.xiaoyuzhoufm.com/episode/xxxxx" /tmp/transcript_raw.json
```

The script extracts the audio URL from the 小宇宙 page, submits an async transcription task to Qwen ASR (`qwen3-asr-flash-filetrans`, supports up to 8-hour episodes), polls until complete (typically 2–5 min), and downloads the JSON result.

**Validation**: Confirm `/tmp/transcript_raw.json` exists and contains a `transcripts` array before proceeding.

### Step 2: Format verbatim transcript

```bash
python3 ./scripts/format_transcript.py /tmp/transcript_raw.json /tmp/transcript_formatted.md
```

Outputs Markdown with `**Speaker** [HH:MM:SS]` headers, auto-splitting paragraphs longer than 300 characters. Speaker detection uses content markers (e.g. "我是XXX"), not model diarization.

**Validation**: Confirm the output file is non-empty and contains at least one `**...**` speaker header.

### Step 3: AI-generated summary (Agent)

Read the formatted transcript, then generate:

1. **核心要点 (Key points)**: 5–8 most important insights, grouped by theme
2. **关键 Q&A (Key Q&A)**: 8–10 question-answer pairs covering core content
3. Write in Chinese, keep tone concise and professional

### Step 4: Assemble final output

Merge the summary and verbatim transcript into one Markdown file saved to `/workspace/podcasts/[播客名称].md`. See `README.md` for the full output template.

**Validation**: Ensure the final file contains all three sections (核心要点, 关键问答, 逐字稿) before reporting success.

## Notes

- Long episodes (1 h+) may take 2–10 min to transcribe; the script polls with a 1-hour timeout
- Speaker identification relies on content markers, not model-based diarization
- Summary quality depends on the OpenClaw session model in use
