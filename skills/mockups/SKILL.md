---
name: mockups
description: Show UI options as HTML mockups in a local browser page so the user can compare them and pick one. Use when the user asks for mockups ("show me mockups", "mockups with superpowers", "show it through the visual companion", "show me options before I decide"), or when a design choice is easier to judge by sight than by text.
---

# Mockups (visual companion)

A small local server shows HTML mockups in the browser. You write HTML files into a folder. The server shows the newest file. The user clicks an option, and the click goes to an events file that you read on your next turn.

Copied from the superpowers plugin 6.4.1 (`skills/brainstorming/visual-companion.md` and `scripts/`), MIT license in `LICENSE`. The scripts are unchanged. They still store sessions under `<project>/.superpowers/brainstorm/`, so existing `.gitignore` entries keep working.

## House rules

- Standing consent: start the server without asking (global CLAUDE.md).
- Open the URL with `cmux-tab <url>`. Never use `--open`. Give the complete URL with its `?key=` part.
- Put 2-4 options on one page (3 is usual). Label them A, B, C. The user answers with one letter in the terminal.
- A clear instruction ("move the button to the right") needs no mockup. Build it.
- Use the browser only when the content is visual: layouts, visual comparisons, look and feel, diagrams. Ask word questions (scope, tradeoffs, API design) in the terminal.

## Start the server

```bash
bash ~/.claude/skills/mockups/scripts/start-server.sh --project-dir /path/to/project

# Returns: {"type":"server-started","port":52341,
#           "url":"http://localhost:52341/?key=ab12…",
#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

Save `screen_dir` and `state_dir`. The script puts the server in the background itself.

- The server rejects a request without the `?key=…` part. After the first load, a cookie holds the key.
- The server writes its startup JSON to `$STATE_DIR/server-info`. Read that file if you did not capture stdout.
- Pass the project root as `--project-dir`, so mockups persist and a restart reuses the same port. Without it, files go to `/tmp`. If `.superpowers/` is not in the project's `.gitignore`, tell the user.

## The loop

1. **Check that the server is alive**: `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does not. If it stopped, run `start-server.sh` again with the same `--project-dir`. It reuses the port, so the open tab reconnects. The server exits after 4 hours idle (`--idle-timeout-minutes`).
2. **Write a new HTML file** into `screen_dir` with the Write tool (not cat or a heredoc). Use a meaningful name (`layout.html`). Never reuse a file name; for a new version, use `layout-v2.html`.
3. **End your turn**: give the URL again, say in one line what the page shows, and ask the user to answer in the terminal (a click is optional).
4. **Next turn**: read `$STATE_DIR/events` if it exists (one JSON object per line). The terminal message is the main answer; the clicks add detail. The last `choice` is usually the final pick. If the file does not exist, the user did not click.
5. **Iterate** with a new file if the feedback changes the page. Move on only when the user accepts the current page.
6. **When the conversation goes back to text**, push a waiting page so the old choice does not stay on screen:

   ```html
   <!-- waiting.html (or waiting-2.html, etc.) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

## Content fragments

Write only the page content. The server wraps it in `scripts/frame-template.html` (header, theme CSS, connection status, click handler). A file that starts with `<!DOCTYPE` or `<html` is served as-is, with only the helper script added. Write fragments unless you need full control of the page.

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

## CSS classes

| Class | Use |
| --- | --- |
| `.options` > `.option[data-choice]` with `.letter` + `.content` | A/B/C choices. Add `data-multiselect` on `.options` for multiple picks. |
| `.cards` > `.card[data-choice]` with `.card-image` + `.card-body` | Visual designs as cards |
| `.mockup` > `.mockup-header` + `.mockup-body` | A framed preview |
| `.split` > two `.mockup` | Side by side |
| `.pros-cons` > `.pros` + `.cons` | Pros and cons lists |
| `.mock-nav`, `.mock-sidebar`, `.mock-content`, `.mock-button`, `.mock-input`, `.placeholder` | Wireframe parts |
| `h2`, `h3`, `.subtitle`, `.section`, `.label` | Title, section heading, secondary text, block, small caps label |

Every clickable element needs `data-choice` and `onclick="toggleSelect(this)"`.

## Events format

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

The server clears the file when you push a new page.

## Design tips

- Match the detail to the question: wireframes for layout, polish for look and feel.
- Put the question on each page ("Which layout feels more professional?").
- Use real content when it matters. Placeholder text hides design problems.

## Stop the server

```bash
bash ~/.claude/skills/mockups/scripts/stop-server.sh $SESSION_DIR
```

With `--project-dir`, the mockup files stay in `.superpowers/brainstorm/`. Only `/tmp` sessions are deleted.
