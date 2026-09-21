status is-interactive; or exit

if type -q eza
    alias ls  'eza --icons --group-directories-first'
    alias ll  'eza -l --icons --group-directories-first --git'
    alias la  'eza -la --icons --group-directories-first --git'
    alias lt  'eza --tree --level=2 --icons'
end
type -q bat; and alias cat 'bat --paging=never --style=plain'

# from .bashrc
alias omo-switch     '~/.config/opencode/switch-omo-config.sh'
alias oc-kimi        'OH_MY_OPENCODE_SLIM_PRESET=kimi-efficient opencode'
alias oc-kimi-deep   'OH_MY_OPENCODE_SLIM_PRESET=kimi-deep opencode'
alias claude-work    'CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
alias cw             'CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
alias claude-personal 'CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'
alias claude-science 'CLAUDE_CONFIG_DIR=$HOME/.claude-science claude'

abbr -a g   git
abbr -a gs  'git status'
abbr -a gd  'git diff'
abbr -a gl  'git log --oneline --graph -20'
abbr -a gp  'git pull'
abbr -a ...  'cd ../..'
