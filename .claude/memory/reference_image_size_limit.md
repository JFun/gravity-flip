---
name: Image dimension / many-images session limit
description: How to recover from "An image in the conversation exceeds the dimension limit for many-image requests (2000px)"
type: reference
originSessionId: ec44e418-270a-4227-a9e2-c21fb280b2f7
---
Anthropic's API enforces a per-image dimension cap when many images
have been sent in one conversation. Once a session has accumulated
several images, individual images larger than 2000 px on either side
get rejected with:

> "An image in the conversation exceeds the dimension limit for
> many-image requests (2000px). Start a new session with fewer images."

**To recover (in priority order):**

1. **Start a fresh session** (`/clear` in Claude Code) — wipes the
   conversation including the prior images, then re-paste only the
   ones you still need.
2. **Resize the new screenshot before pasting.** macOS:
   `sips -Z 1600 in.png --out out.png` (max 1600 on the long side).
   iOS screenshots are 1170×2532 (iPhone 13 Pro) or 1290×2796 (Pro Max)
   — the long side already exceeds 2000, which is what triggers it.
3. **Keep fewer images per session.** Delete or summarize prior
   screenshots once they've served their purpose.

**Avoiding it during long iteration sessions:** when iterating on UI
on a phone, the screenshots stack up fast. Either pre-resize all
screenshots to ≤1600 long-side, or split the work across sessions and
carry forward only verbal context.
