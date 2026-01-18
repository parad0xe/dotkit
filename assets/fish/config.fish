if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_prompt
    # Sauvegarder le code retour de la dernière commande
	set -l last_status $status

	# Couleur selon succès/échec
	set -l color_status (test $last_status -eq 0; and echo green; or echo red)
	set -l status_str (set_color $color_status)"[$last_status]"(set_color normal)

	# Nom d'utilisateur (cyan)
	set -l user_str (set_color cyan)(whoami)(set_color normal)

	# PWD (violet)
	set -l pwd_str (set_color magenta)(prompt_pwd)(set_color normal)

	# Git (jaune)
	set -l git_str (set_color yellow)(fish_git_prompt)(set_color normal)

	# Prompt final
	echo ""
	echo "$status_str $user_str $pwd_str$git_str"
	echo -n (set_color $color_status)"> "(set_color normal)
end

set -g fish_prompt_pwd_dir_length 4

set -Ua fish_user_paths $HOME/.cargo/bin

if type -q pyenv
	export PYENV_ROOT="$HOME/.pyenv"
	set -Ua fish_user_paths $PYENV_ROOT/bin
	pyenv init - | source
end

alias francinette="/home/parad0xe/francinette/tester.sh"
alias paco="/home/parad0xe/francinette/tester.sh"
alias c="cc -Wall -Wextra -Werror"
alias n="norminette"
alias ll="ls -la"
alias tree="tree -C -a -I .git"
alias vim="nvim"
alias cat="pygmentize -g"
