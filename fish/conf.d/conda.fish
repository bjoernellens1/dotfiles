# conda / mamba (miniforge3) — lazy: base env not auto-activated, `conda activate` works
if test -f $HOME/miniforge3/bin/conda
    if status is-interactive
        eval $HOME/miniforge3/bin/conda "shell.fish" hook $argv | source
    else
        fish_add_path -g $HOME/miniforge3/bin
    end
end
if test -f $HOME/miniforge3/bin/mamba
    set -gx MAMBA_EXE $HOME/miniforge3/bin/mamba
    set -gx MAMBA_ROOT_PREFIX $HOME/miniforge3
    status is-interactive; and $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
end
