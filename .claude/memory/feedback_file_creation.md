---
name: Use Write tool for new files
description: Always use the Write tool to create new files; never use cat heredocs or echo redirection via Bash
type: feedback
originSessionId: 81f843f2-db11-4d20-9cfc-764d94a96cda
---
When creating new files, use the Write tool. Do not use `cat <<EOF`, `echo >`, or similar Bash redirection.

**Why:** User explicitly requested this. The Write tool gives a clean diff/permission UX; heredocs are noisy and harder to review.

**How to apply:** Any new file → Write tool. Editing existing files → Edit tool. Bash file output is only acceptable when the content comes from a real command (e.g. `godot --export ... > out.pck`), not when I'm authoring the content myself.
