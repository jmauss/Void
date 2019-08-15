#!/usr/bin/env zsh

autoload -Uz compinit
compinit

# zsh-completion settings
zstyle ':completion:*' menu select

zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  '+l:|?=** r:|?=**'

# Enable colors
autoload -Uz colors && colors

# dwm prompt
PROMPT="[%{$fg_bold[green]%}%n%{$reset_color%}:%~%{$reset_color%}]$ "

# History
setopt HIST_IGNORE_DUPS

autoload -U history-search-end

zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

bindkey "\e[A" history-beginning-search-backward-end
bindkey "\e[B" history-beginning-search-forward-end

HISTSIZE=10000
if (( ! EUID )); then
  HISTFILE=~/.history_root
else
  HISTFILE=~/.history
fi
SAVEHIST=10000

# Alias 
alias ls='ls --color=auto'
alias please='sudo $(fc -ln -1)'
alias sudo='sudo '
alias xi='sudo xbps-install'
alias xr='sudo xbps-remove'
alias xq='xbps-query'
