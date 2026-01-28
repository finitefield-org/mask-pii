#!/usr/bin/env zsh

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/../../zsh/mask-pii.plugin.zsh"

mask_pii_new masker
mask_pii_mask_emails masker
mask_pii_mask_phones masker
mask_pii_with_mask_char masker "#"

input_text="Contact: alice@example.com or 090-1234-5678."
output=$(mask_pii_process masker "$input_text")

print -r -- "$output"
