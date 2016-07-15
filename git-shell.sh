source /usr/share/doc/git/contrib/completion/git-completion.bash
alias g=git
complete -o default -o nospace -F _git g

source /usr/share/doc/git/contrib/completion/git-prompt.sh
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
