#!/usr/bin/env bash
# Install fish + kitty + starship dotfiles. Idempotent; existing files are backed up to *.bak.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

# --- packages -----------------------------------------------------------------
if command -v dnf >/dev/null; then
  sudo dnf install -y fish kitty fzf zoxide eza bat
elif command -v apt-get >/dev/null; then
  sudo apt-get install -y fish kitty fzf zoxide eza bat
elif command -v pacman >/dev/null; then
  sudo pacman -S --needed --noconfirm fish kitty fzf zoxide eza bat
else
  echo "unknown package manager: install fish kitty fzf zoxide eza bat manually" >&2
fi

# --- starship (not in Fedora repos) ------------------------------------------
mkdir -p "$HOME/.local/bin"
command -v starship >/dev/null || \
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"

# --- Nerd Font ----------------------------------------------------------------
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if ! fc-list | grep -q "JetBrainsMono Nerd Font"; then
  mkdir -p "$FONT_DIR"
  curl -sSL -o /tmp/jbm.tar.xz \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  tar -xf /tmp/jbm.tar.xz -C "$FONT_DIR" && rm /tmp/jbm.tar.xz
  fc-cache -f
fi

# --- symlink configs ----------------------------------------------------------
link() {  # link <repo-relative-src> <dest>
  local src="$HERE/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak"; fi
  ln -sfn "$src" "$dst"
  echo "  $dst -> $src"
}
echo "linking:"
link kitty/kitty.conf          "$CFG/kitty/kitty.conf"
link kitty/theme.conf          "$CFG/kitty/theme.conf"
link fish/config.fish          "$CFG/fish/config.fish"
link fish/fish_plugins         "$CFG/fish/fish_plugins"
for f in "$HERE"/fish/conf.d/*.fish; do
  link "fish/conf.d/$(basename "$f")" "$CFG/fish/conf.d/$(basename "$f")"
done
link starship/starship.toml    "$CFG/starship.toml"

# --- halogen (Strix Halo only; quadlets are inert elsewhere) -----------------------
if [ -e /dev/kfd ] && grep -qs "gfx_target_version 110501" /sys/class/kfd/kfd/topology/nodes/*/properties; then
  mkdir -p "$CFG/containers/systemd" "$HOME/halogen-flash-models" "$HOME/halogen-flash-cache"
  link halogen/halogen-flash.container      "$CFG/containers/systemd/halogen-flash.container"
  link halogen/halogen-flash-proxy.socket   "$CFG/systemd/user/halogen-flash-proxy.socket"
  link halogen/halogen-flash-proxy.service  "$CFG/systemd/user/halogen-flash-proxy.service"
  loginctl enable-linger "$USER" 2>/dev/null || true
  systemctl --user daemon-reload && systemctl --user enable --now halogen-flash-proxy.socket
  echo "  halogen: socket on :8731 (model starts on first connection); see halogen/README.md"
fi

# --- Fisher + plugins ---------------------------------------------------------
fish -c '
  if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
  end
  fisher update
'

# --- KDE: make kitty the default terminal --------------------------------------
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
  kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
fi

echo
echo "done. Open a new kitty window. bash stays your login shell; kitty starts fish."
