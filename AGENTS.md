# Agent Personas

All agents MUST be **extremely succinct** when creating documentation — no unneeded docs unless explicitly asked.
All agents MUST be honest — find the best solution, don't try to please.

---

## Workstation Operator

Personal dotfiles, symlinked into `$HOME` via [dotbot](https://github.com/anishathalye/dotbot) (`./install` + `install.conf.yaml`). The Workstation Operator role owns everything in this repo:

- Shell — `zsh`, oh-my-zsh, powerlevel10k, aliases, exports, path
- Terminal & multiplexer — `tmux.conf`, tpm plugins
- Editors — `nvim/`, `vimrc`, `ideavimrc`, `doom-emacs/`
- Tooling glue — `gitconfig`, `lazygit.yml`, `fzf`, `ssh-agent`, `pyenv-init`, `nvm-init`, `topgrade.toml`

**Final call on**: which configs are tracked, link layout in `install.conf.yaml`, prerequisite tooling, key bindings and theme choices.

## Doom Emacs

`~/.config/doom` is a symlink to `doom-emacs/`; the running Emacs (systemd user service `emacs`, Doom in `~/.config/emacs`) loads it live. Workflow, keys and design reasons: `doom-emacs/README.md`.

- `config.el`, `functions/*.el`: apply with `emacsclient -e '(load "~/.config/doom/functions/X.el" nil t)'`, or the user runs `eval-buffer`.
- In a task worktree (`.worktrees/<branch>`), `~/.config/doom` is still the main checkout: to try an edit live, load the file by its worktree path. The main checkout's version comes back at the next restart until the branch is merged.
- `init.el`, `packages.el`: need `doom sync` and a daemon restart.
- Ask before `doom sync`, `doom upgrade`, restarting or killing the daemon, and any `emacsclient -e` that changes windows or workspaces. Reading state is fine.
- `functions/agents.el` uses internal ai-code functions (unpinned): check the installed source in `~/.config/emacs/.local/straight/repos/ai-code-interface.el/` before relying on one.
- After each change, say whether it needs a load, `doom sync` or a restart.
- Gate: `pre-commit run doom-elisp --all-files` passes before any elisp change is committed or loaded into the running Emacs.

## Commits

- `main` is protected: branch, PR, squash merge only when told.
- Commits are SSH-signed with `~/.ssh/id_github`, and so are pushes. Run `source "$XDG_RUNTIME_DIR/ssh-agent.env"` first. Keys expire after 12 hours: if `ssh-add -l` doesn't list the key, a commit hangs; ask the user to run `ssh-add ~/.ssh/id_github`, never skip signing.
- In an agent's shell, `pre-commit` is `~/.local/bin/pre-commit`, and `emacs` is an alias for emacsclient: use `/usr/bin/emacs` for batch runs.
