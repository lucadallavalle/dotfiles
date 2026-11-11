# Doom Emacs: agent workflow

One task = one git branch + one worktree + one Doom workspace + one agent.
Agents run through [ai-code](https://github.com/tninja/ai-code-interface.el); the backend is set in `config.el` (`claude-code`, later `pi`).

## Files

- `config.el`: ai-code setup, Magit worktree section, loads everything in `functions/`.
- `functions/agents.el`: the `SPC j` commands.
- `functions/sessions.el`: on the daemon's first frame, restores the last session and resumes all task agents.

## Keys

| Key       | Action                                                        |
| --------- | ------------------------------------------------------------- |
| `SPC j n` | New task: branch, worktree, workspace, agent                  |
| `SPC j g` | Magit for this task's worktree                                |
| `SPC j f` | Finish task (after merging): stop agent, remove worktree      |
| `SPC j r` | Resume the agent here (`SPC u SPC j r`: fresh conversation)   |
| `SPC j R` | Resume agents in all task workspaces                          |
| `SPC j h` | Workspace + agent on the main checkout, for questions         |
| `SPC j s` | Scratch agent in `~/scratch`                                  |
| `SPC j a` | One-off question, no session                                  |
| `SPC j d` | Toggle the sessions dashboard                                 |
| `SPC j j` | Jump to a workspace                                           |
| `SPC o c` | ai-code menu                                                  |

## How it works

- Worktrees live at `<repo>/.worktrees/<branch>`, ignored through `.git/info/exclude`.
- Workspaces are named `repo:branch`. Each stores its worktree path as a workspace parameter, saved with the session.
- Resume continues the latest conversation in the worktree (`--continue`), without a picker.
- The task file is the prompt notebook: write under a heading, `C-c C-c` sends it to the task's agent. The real file is in the main checkout's `.ai.code.files/`, symlinked into the worktree, so it survives `SPC j f`.
- The dashboard refreshes every 10 seconds while visible.

## After changes

Edits to `config.el` or `functions/` need a daemon restart (or `M-x eval-buffer`). `doom sync` only after changing `init.el` or `packages.el`.
