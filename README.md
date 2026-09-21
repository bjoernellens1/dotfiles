# dotfiles — fish + kitty + starship

Fedora/KDE-oriented terminal setup. bash stays the login shell (so `.bash_profile`
logic keeps working); **kitty launches fish** — the approach fish itself recommends.

| piece | what |
|---|---|
| `kitty/kitty.conf` | fish as shell, JetBrainsMono Nerd Font, powerline tabs, 20k scrollback, shell integration |
| `kitty/theme.conf` | Catppuccin Mocha |
| `fish/config.fish` | PATH, env, starship, zoxide |
| `fish/conf.d/aliases.fish` | eza `ls/ll/la/lt`, `cat`→bat, git abbrs, tool aliases |
| `fish/conf.d/conda.fish` | conda/mamba hooks (`~/miniforge3`); `base` not auto-activated |
| `fish/conf.d/kitty.fish` | `icat`, `ssh`→`kitten ssh`, `d`→`kitten diff` |
| `fish/fish_plugins` | Fisher: fzf.fish, autopair |
| `starship/starship.toml` | dir · git branch/status · venv · node · duration |

## Install

```sh
git clone https://github.com/bjoernellens1/dotfiles ~/git/dotfiles
~/git/dotfiles/install.sh
```

`install.sh` installs packages (dnf/apt/pacman), starship to `~/.local/bin`, the
Nerd Font to `~/.local/share/fonts`, symlinks the configs into `~/.config`
(existing files → `*.bak`), runs Fisher, and sets kitty as KDE's default terminal.

## Keys

**kitty** (`kitty_mod` = Ctrl+Shift)

| key | action |
|---|---|
| `Ctrl+Shift+T` / `Enter` / `N` | new tab / split / OS window in cwd |
| `Ctrl+Tab`, `Alt+1..5` | switch tabs |
| `Ctrl+Shift+H` | scrollback in pager |
| `Ctrl+Shift+F` | fzf over scrollback |
| `Ctrl+Shift+=` / `-` / `0` | font size |
| `Ctrl+Shift+F5` | reload config |

**fish / fzf.fish**

| key | action |
|---|---|
| `Ctrl+R` | history |
| `Ctrl+Alt+F` | files |
| `Ctrl+Alt+L` / `Ctrl+Alt+S` | git log / git status |
| `z dir`, `zi` | zoxide jump / interactive |

## Notes

- fish errors on unmatched globs (`fzf *.ply` → use `fd -e ply \| fzf`).
- To make fish the login shell anyway: `chsh -s /usr/bin/fish` — then port
  anything from `.bash_profile` you rely on.
- `fish_config` opens a web UI for colours/prompt.
