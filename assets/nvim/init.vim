call plug#begin()

Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'sainnhe/everforest'
Plug 'AlexvZyl/nordic.nvim', { 'branch': 'main' }
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
Plug 'kdheepak/lazygit.nvim'
Plug 'tpope/vim-surround'
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }
Plug 'mfussenegger/nvim-lint'
Plug 'folke/tokyonight.nvim'
Plug 'xiyaowong/transparent.nvim'
Plug 'tamton-aquib/staline.nvim'
Plug 'sphamba/smear-cursor.nvim'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'nxhung2304/lastplace.nvim'

call plug#end()

syntax on
set nu
set colorcolumn=79
set tabstop=4
set shiftwidth=4
set smartindent
set autoindent

set undofile
set undodir=~/.local/share/nvim/undo/
set undolevels=100

" colorscheme nordic
colorscheme tokyonight-moon
" colorscheme everforest

function! Header()
	"==================  editing header file =====================
	let header = expand("%:t:r")
	call append(0,"#ifndef ".toupper(header)."_H")
	call append(1,"# define ".toupper(header)."_H")
	call append(2,"")
	call append(3,"")
	call append(4,"")
	call append(5,"#endif")
	call cursor(4, 0)
endfunction

function! Main()
	"==================  editing header file =====================
	call append(0,"#include <>")
	call append(1,"")
	call append(2,"int	main(int argc, char *argv[])")
	call append(3,"{")
	call append(4,"\t")
	call append(5,"\treturn (0);")
	call append(6,"}")
	call cursor(5, 0)
endfunction

command! -nargs=0 Header call Header()
command! -nargs=0 Main call Main()

source ~/.vim/plugin/stdheader.vim
source ~/.config/nvim/config.lua

let g:user42 = 'nlallema'
let g:mail42 = 'nlallema@student.42lyon.fr'

let g:doge_doc_standard_python = 'google'
