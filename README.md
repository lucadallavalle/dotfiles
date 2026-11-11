# dotfiles

Personal Linux workstation config: `zsh`, `tmux`, Neovim, Doom Emacs and the glue around them. Symlinked into `$HOME` with [dotbot](https://github.com/anishathalye/dotbot).

## Install

```sh
git clone git@github.com:lucadallavalle/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

`./install` fetches dotbot (a submodule) and creates the links listed in `install.conf.yaml`. It is safe to re-run.

## What's inside

| Path                           | Linked to                      | What                                                          |
| ------------------------------ | ------------------------------ | ------------------------------------------------------------- |
| `zshrc`                        | `~/.zshrc`                     | oh-my-zsh, powerlevel10k; sources the files below             |
| `aliases`, `exports`, `path`   | `~/.aliases`, …                | Shell aliases, environment, `PATH`                            |
| `p10k.zsh`                     | `~/.p10k.zsh`                  | Prompt theme                                                  |
| `fzf`, `pnpm`, `ng`, `thefuck` | `~/.fzf`, …                    | Per-tool shell init, each skipped if the tool is missing      |
| `ssh-agent`                    | `~/.ssh-agent`                 | Starts one shared `ssh-agent` per login                       |
| `tmux.conf`                    | `~/.tmux.conf`                 | tmux with tpm plugins                                         |
| `nvim/`                        | `~/.config/nvim`               | Neovim, plugins managed by lazy.nvim                          |
| `vimrc`, `ideavimrc`           | `~/.vimrc`, `~/.ideavimrc`     | Vim and JetBrains IdeaVim                                     |
| `doom-emacs/`                  | `~/.config/doom`               | Doom Emacs, see [its README](doom-emacs/README.md)            |
| `gitconfig`, `lazygit.yml`     | `~/.gitconfig`, lazygit config | Git and lazygit                                               |
| `topgrade.toml`                | `~/.config/topgrade.toml`      | System-wide updates with topgrade                             |
| `plasma-workspace/`            | `~/.config/plasma-workspace`   | KDE Plasma session environment                                |

## Prerequisites

Shell and tmux:

1. [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh): via package manager, or `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
2. [powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh): `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`
3. [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): `git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
4. [tpm](https://github.com/tmux-plugins/tpm): `git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`, then open `tmux` and press `prefix + I`
5. A [nerd font](https://github.com/ryanoasis/nerd-fonts) (the prompt relies on its glyphs). Doom is set to Fira Code.

Editors:

- Neovim installs its plugins on first start.
- [Doom Emacs](https://github.com/doomemacs/doomemacs) goes in `~/.config/emacs`; run `doom sync` after linking.

## Contributing

`main` only takes pull requests (squash merge). [pre-commit](https://pre-commit.com) hooks run on commit: `pre-commit install`.
