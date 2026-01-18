#!/bin/bash

ASSETS=$PWD/assets
TMP=$PWD/tmp

function install_vim_plug
{
	echo ""
	echo "== Install Vim Plug =="
	if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]; then
		sh -c 'curl -sfLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim \
			--create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' \
			1>/dev/null
		status=$?
		if [ $status -ne 0 ]; then
			echo "failed";
			exit 1
		fi
	fi
	echo "done"
}

function install_nerd_font
{
	echo ""
	echo "== Install Nerd Font =="
	if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNLNerdFont-Thin.ttf" ]; then
		mkdir -p $TMP/nerd-font
		mkdir -p $HOME/.local/share/fonts
		wget -qP $TMP/nerd-font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
		cd $TMP/nerd-font
		unzip JetBrainsMono.zip 1>/dev/null
		mv *.ttf $HOME/.local/share/fonts
		cd ../..
		fc-cache -fv 1>/dev/null
	fi
	echo "done"
}

function install_bin
{
	echo ""
	echo "== Install binaries =="
	mkdir -p $HOME/.local/bin
	for bin in $(ls $ASSETS/bin); do
		echo -n "install $bin into $HOME/.local/bin.. "
		ln -Tsf $ASSETS/bin/$bin $HOME/.local/bin
		echo "OK"
	done
	echo "done"
}

function install_scripts
{
	echo ""
	echo "== Install scripts =="
	mkdir -p $HOME/.local/bin
	for bin in $(ls $ASSETS/scripts); do
		echo -n "install $bin into $HOME/.local/bin.. "
		ln -Tsf $ASSETS/scripts/$bin $HOME/.local/bin
		echo "OK"
	done
	echo "done"
}

function configure_nvim
{
	echo ""
	echo "== Install nvim configuration =="
	mkdir -p $HOME/.config/nvim/lua
	ln -Tsf $ASSETS/nvim/config.lua $HOME/.config/nvim/config.lua
	ln -Tsf $ASSETS/nvim/init.vim $HOME/.config/nvim/init.vim 
	ln -Tsf $ASSETS/nvim/lua/config $HOME/.config/nvim/lua/config 
	echo "done"
}

function configure_fish
{
	echo ""
	echo "== Install fish configuration =="
	mkdir -p $HOME/.config/fish
	ln -Tsf $ASSETS/fish/config.fish $HOME/.config/fish/config.fish
	echo "done"
}

install_vim_plug
install_nerd_font
install_bin
install_scripts
configure_nvim
configure_fish

rm -rf $TMP

echo ""
echo "[info] open nvim and run :PlugInstall"
