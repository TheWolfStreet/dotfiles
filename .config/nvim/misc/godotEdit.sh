#!/usr/bin/env bash

term_exec="konsole"
nvim_exec="nvim"
server_path="$HOME/.cache/nvim/godot-server.pipe"

start_server() {
	"$term_exec" -e "$nvim_exec" --listen "$server_path" "$1"
}

open_file_in_server() {
	"$nvim_exec" --server "$server_path" --remote-send "<C-\><C-n>:e $1<CR>:$2<CR>"
}

if ! [ -e "$server_path" ]; then
	start_server "$1"
else
	open_file_in_server "$1" "$2"
fi
