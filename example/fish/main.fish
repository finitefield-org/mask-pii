#!/usr/bin/env fish

set -l root (cd (dirname (status --current-filename))/../..; pwd)
set -l functions_dir "$root/fish/functions"
set -g fish_function_path $functions_dir $fish_function_path
source "$functions_dir/mask_pii.fish"

set -l input_text "Contact: alice@example.com or 090-1234-5678."
set -l output (mask_pii --emails --phones --mask-char '#' "$input_text")

echo $output
