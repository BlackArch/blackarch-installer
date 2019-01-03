### BlackArch Linux settings ###

# umask
umask 077

# colors
darkgrey="$(tput bold ; tput setaf 0)"
white="$(tput bold ; tput setaf 7)"
red="$(tput bold; tput setaf 1)"
nc="$(tput sgr0)"

# exports
export PATH="${HOME}/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:"
export PATH="${PATH}/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:"
export PS1="\[$darkgrey\][ \[$red\]\H \[$white\]\W\[$red\] \[$darkgrey\]]\\[$red\]# \[$nc\]"
export LD_PRELOAD=""
export EDITOR="vim"

# alias
alias c="clear"
alias cd..="cd .."
alias curl="curl --user-agent 'noleak'"
alias l="ls -ahls --color"
alias ls="ls --color"
alias python="python2"
alias r="reset"
alias shred="shred -zf"
alias sl="ls --color"
alias vi="vim"
alias wget="wget -c --user-agent 'noleak'"
alias www="python -m SimpleHTTPServer"

# source files
[ -r /usr/share/bash-completion/completions ] &&
  . /usr/share/bash-completion/completions/*
