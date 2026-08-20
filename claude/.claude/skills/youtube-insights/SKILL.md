---
name: youtube-insights
description: Extract signal from a YouTube video via link or pasted transcript. Auto-detects whether the video is procedural (how something works/how-to) and outputs numbered steps, or a discussion/opinion video and outputs key insights. Use when the user shares a YouTube link or transcript and asks to summarize it, pull out the steps, or distill insights.
---

# youtube-insights

## Purpose

Turn a YouTube video (link or pasted transcript) into signal: either the
concrete steps if it's a how-it-works/how-to video, or the key insights/claims
if it's a discussion, opinion, or conceptual video. Skip the padding, skip
restating the whole transcript.

## Delegation

The raw transcript can be tens of thousands of characters — don't let it land
in the calling conversation's context. Do steps 1-3 inside a subagent (the
`Agent` tool, `general-purpose` type, no isolation needed) and have it return
only the finished Markdown from Step 3. The caller passes the URL or pasted
transcript into the subagent prompt; the subagent fetches, classifies, and
formats, then reports back just the summary.

## Step 1: Get the transcript

If given a link, extract the video ID and fetch the transcript:

```bash
python3 -c "import youtube_transcript_api" 2>/dev/null || pip install youtube-transcript-api
```

```python
from youtube_transcript_api import YouTubeTranscriptApi

video_id = "VIDEO_ID"  # from ?v= or youtu.be/ path
api = YouTubeTranscriptApi()
transcript = api.fetch(video_id).to_raw_data()
full_text = " ".join(t["text"] for t in transcript)
```

If `youtube-transcript-api` fails (transcripts disabled, no captions), tell
the user and stop — don't guess at content.

If given a pasted transcript directly, skip straight to Step 2.

## Step 2: Detect video type

Read the transcript. Classify as one of:

- **Procedural** — explains how something works, how to do/build/configure
  something, a tutorial, a walkthrough. Signal = the sequence of steps,
  including any decision points, prerequisites, or gotchas the video calls out.
- **Discussion/conceptual** — opinion, analysis, interview, news, lecture
  without a concrete procedure. Signal = the key claims, arguments, and
  takeaways.

A video can be both (e.g. a tutorial with framing/opinion around it) — if so,
output both sections.

## Step 3: Output

Keep it short. No restating the intro/outro, no filler, no "in this video
the speaker discusses." State the content directly.

**Procedural format:**

```markdown
# [Video title]

## Steps
1. [action] — [only the detail needed to do it, incl. exact commands/values if given]
2. ...

## Gotchas / prerequisites
- [anything the video flags as a trap, requirement, or edge case]
```

**Discussion format:**

```markdown
# [Video title]

## Key insights
- [claim/point 1, stated plainly]
- ...

## Worth following up
- [anything named as a source, tool, or reference worth checking]
```

Omit a section entirely if there's nothing in it — don't pad with "N/A".
