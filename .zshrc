# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions zsh-autopair)

source "$HOME/.zsh/functions"

alias pacman="sudo pacman"

export EDITOR=nvim

export DOCKER_HOST=unix:///run/user/1000/docker.sock

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

eval "$(zoxide init --cmd cd zsh)"

export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
export TERMINFO=/usr/share/terminfo

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
