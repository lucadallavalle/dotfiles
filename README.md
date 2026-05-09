# dotfiles

Personal dotfiles, mostly tuning `zsh` appearance and `tmux` behaviour. Managed with [dotbot](https://github.com/anishathalye/dotbot).

## Install

```sh
./install
```

Symlinks everything per `install.conf.yaml` and pulls submodules.

## Prerequisites

1. [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) — via package manager, or `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
2. [powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh) — `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`
3. [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — `git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
4. [tpm](https://github.com/tmux-plugins/tpm) — `git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
5. A [nerd font](https://github.com/ryanoasis/nerd-fonts) (the theme relies on its glyphs).

Then open `tmux` and press `prefix + I` to install plugins.
