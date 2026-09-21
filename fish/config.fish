# ── PATH (mirrors .bashrc / .bash_profile; fish_add_path is idempotent) ─────
fish_add_path -g ~/.local/bin ~/bin ~/.npm-global/bin ~/.opencode/bin \
    ~/.kimi-code/bin ~/.bun/bin ~/.lmstudio/bin ~/.local/share/clauth/current@claude/bin

set -gx BUN_INSTALL $HOME/.bun
set -gx EDITOR nano
set -gx VISUAL "code --wait"
# opencode: do not import ~/.claude/CLAUDE.md (Claude Code agent policy names agents opencode lacks)
set -gx OPENCODE_DISABLE_CLAUDE_CODE_PROMPT 1

status is-interactive; or exit

# ── Interactive only ────────────────────────────────────────────────────────
set -g fish_greeting                      # no welcome banner

# fzf.fish (Fisher): Ctrl-R history, Ctrl-Alt-F files, Ctrl-Alt-L git log, Ctrl-Alt-S git status
if type -q fzf
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"
end

# zoxide: `z dir`, `zi` interactive
type -q zoxide; and zoxide init fish | source

# starship prompt
type -q starship; and starship init fish | source
