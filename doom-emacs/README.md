# Doom Emacs: agent workflow

One task = one git branch + one worktree + one Doom workspace + one agent.
Agents run through [ai-code](https://github.com/tninja/ai-code-interface.el); the backend is set in `config.el` (`claude-code`, later `pi`).

## Files

- `config.el`: ai-code setup, Magit worktree section, loads everything in `functions/`.
- `functions/agents.el`: the `SPC j` commands.
- `functions/sessions.el`: on the daemon's first frame, restores the last session and resumes all task agents; saves the session when idle.

## Keys

| Key       | Action                                                        |
| --------- | ------------------------------------------------------------- |
| `SPC j n` | New task: branch, worktree, workspace, agent                  |
| `SPC j o` | Reopen an existing task worktree (workspace lost)             |
| `SPC j g` | Magit for this task's worktree                                |
| `SPC j e` | File tree (treemacs) for this task's worktree                 |
| `SPC j l` | Restore the layout: agent, file tree, dashboard               |
| `SPC j z` | Zoom the current window full frame; again to restore          |
| `SPC j f` | Finish task (after merging): stop agent, remove worktree      |
| `SPC j r` | Resume the agent here (`SPC u SPC j r`: fresh conversation)   |
| `SPC j R` | Resume agents in all task workspaces                          |
| `SPC j p` | Pick an earlier conversation (stops the running agent)        |
| `SPC j h` | Workspace + agent on the main checkout, for questions         |
| `SPC j s` | Scratch agent in `~/scratch`                                  |
| `SPC j a` | One-off question, no session                                  |
| `SPC j d` | Toggle the sessions dashboard                                 |
| `SPC j j` | Jump to a workspace                                           |
| `SPC o c` | ai-code menu                                                  |

## How it works

- Worktrees live at `<repo>/.worktrees/<branch>`. They, `.ai.code.files/` and the task-file links are ignored through `.git/info/exclude`, so nothing of this is ever committed.
- Workspaces are named `repo:branch`. `SPC j h` in the workspace Doom made when the project was opened renames that one instead of adding a second. Each stores its worktree path as a workspace parameter, saved with the session.
- Resume continues the latest conversation in the worktree (`--continue`), without a picker.
- The task file is the prompt notebook: write under a heading, `C-c C-c` sends it to the task's agent. The real file is in the main checkout's `.ai.code.files/`, symlinked into the worktree, so it survives `SPC j f`.
- `SPC j n`, `SPC j o`, `SPC j h` and the restore open the file tree on the checkout and the dashboard.
- The dashboard refreshes every 10 seconds while visible. In it: `RET` jumps to the session's workspace, `g r` refreshes, `x` kills the session, `D` opens Magit, `q` hides it.

## A task, start to finish

1. `SPC j n` from any file in the repo: pick the start point, name the branch, say `y` to the task file.
2. In the task file, write the request under a heading and press `C-c C-c` on it. Three prompts follow:
   `Code change` (edit files) or `Ask question` (answer only); an instruction line to accept or extend with `RET`; whether the agent appends a summary to the task file.
3. Review with `SPC j g`. Merge from the main checkout: `SPC j h`, `SPC g g`, `m m`.
4. `SPC j f` in the task workspace.

After a daemon restart the task and home workspaces, agents (with their conversations), trees and dashboard come back by themselves.

## Magit and review keys

Keys differ from stock Magit because of evil.

| Key                   | Where          | Action                                             |
| --------------------- | -------------- | -------------------------------------------------- |
| `TAB`                 | Magit          | Expand or collapse a file or hunk                  |
| `s` / `u`             | Magit          | Stage / unstage what is under the cursor           |
| `x`                   | Magit          | Discard what is under the cursor                   |
| `c c`, then `C-c C-c` | Magit          | Commit (`C-c C-k` cancels)                         |
| `]` / `[`             | Magit          | Next / previous file or hunk                       |
| `RET`                 | Magit          | Open the file at that line                         |
| `` SPC ` ``           | anywhere       | Back to the previous buffer                        |
| `SPC g ]` / `SPC g [` | file           | Next / previous changed hunk                       |
| `b b`, `b c`, `b x`   | Magit          | Switch, create, delete a branch                    |
| `m m`, `P p`, `F p`   | Magit          | Merge, push, pull                                  |
| `g r`, `q`, `?`       | Magit          | Refresh, close, all commands                       |
| `SPC w u`             | anywhere       | Undo the last window layout change                 |

## Why it is built this way

- **Worktree stored on the workspace, not derived from buffers.** Doom opens symlinks as their real file, so the task file looks like it belongs to the main checkout, and a workspace's buffer list can be empty.
- **Task files are re-tied to their worktree on open** (`find-file-hook`). ai-code keeps that link buffer-local, so it is lost on reopen and prompts would go to the main checkout.
- **`SPC j e` instead of `SPC o p`.** Treemacs keeps showing the main checkout in a task workspace.
- **`SPC j z` instead of `SPC w m m`.** Agent, tree and dashboard are side windows: `delete-other-windows` keeps them, and refuses to run from one.
- **Dashboard keys are rebound for evil.** Normal state hides the dashboard's own keys. `RET` is advised to switch workspace rather than pull the agent's buffer into the current one.
- **Dashboard refresh timer.** ai-code never refreshes it by itself.
- **Live agents are put back in the session list on every refresh.** ai-code cleans up a dead agent by buffer name and can drop a running one that reused the name.
- **No popup rule for the dashboard.** The `^\*` catch-all only exists with `(popup +all)`; this config uses `+defaults`.
- **`--continue`, not ai-code's resume.** ai-code's resume opens a picker per agent. `my/agent-continue-switches` maps each backend to its flag; Claude Code and Pi both use `--continue`.
- **Handoffs stay in the repo's own `docs/HANDOVER.md`** (agentfiles convention), which works without Emacs. ai-code's handoff and task-resume commands are deliberately unbound.
- **`SPC TAB x` unbound.** Doom's "Kill session" deletes every workspace and agent in one key press.
- **Agents resume after every session load** (`SPC q l` too), not only at daemon start.
- **Layouts are saved without side windows**, and the panels are redrawn on each switch to a task or home workspace. Restoring side windows whose buffers are gone failed and lost the whole layout. Doom popups aren't saved either.
- **Folder trust**: Claude Code asks once per repo if the repo root is trusted, since worktrees live inside it.

## Not yet exercised

As of 2026-11-11: `SPC j o`, `SPC j s`, `SPC j a`, home workspace resume after a restart. As of 2026-11-14: `SPC j p`.

## After changes

- `config.el` or `functions/`: restart the daemon, or `M-x eval-buffer`.
- `init.el` or `packages.el`: `~/.config/emacs/bin/doom sync`, then restart the daemon.
- Restart the daemon: `systemctl --user restart emacs`, then `emacsclient -c`. `SPC q q` only closes the frame.
- The session saves itself after two idle minutes and on exit; `SPC q s` forces a save right now.
- `doom upgrade` can rebuild `.local` and drop the saved session: bring each task back with `SPC j o`.
- `doom upgrade` also updates ai-code, whose internal functions `functions/agents.el` relies on: retest `SPC j n`, `SPC j g` and the dashboard afterwards.
