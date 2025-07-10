# 🤜 jab.nvim

Motion plugin with label-hinting supporting Japanese (migemo).

Hit jabs to where you want to go with following motions!

- incremental-search motions
- f/F/t/T-like motions

They are dot-repeatable, so you can hit as many jabs as you want.

## Recommendation

To hit jabs on Japanese characters, you need following plugins.

- https://github.com/lambdalisue/vim-kensaku
- https://github.com/vim-denops/denops.vim

## Demo

### Incremental search

![2024-11-26 12-26-31 mkv](https://github.com/user-attachments/assets/f50e5eb0-4441-494a-b4bc-c76aaf0e900c)

### f-motions

![2024-11-26 12-27-03 mkv](https://github.com/user-attachments/assets/d0689b8e-0945-4152-b1b7-6bdfa0cc4b03)

## Configurations

```lua
-- incremental search
-- if vim-kensaku is available and initial query is uppercase,
-- then the search is case-sensitive.
-- Otherwise, the search is case-insensitive.
-- hints appear on the left of the matches if possible.
vim.keymap.set({ "n", "x", "o" }, ";", function()
	return require("jab").jab_win()
end, { expr = true })

-- f-motions
-- search is always case-sensitive
-- hints appear exactly on the matches.
vim.keymap.set({ "n", "x", "o" }, "f", function()
	return require("jab").f()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", function()
	return require("jab").F()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", function()
	return require("jab").t()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", function()
	return require("jab").T()
end, { expr = true })
```

This plugin is based on my use case, so it has limited configurabilities.

Exceptionally, you can provide custome-labels like below.

```lua
vim.keymap.set({ "n", "x", "o" }, "f", function()
	return require("jab").f({ labels = { "a", "b", "c" } })
end, { expr = true })
```

Default labels are as follows.

- f/F/t/T: See `require("jab").labels_f` 
- jab_win: See `require("jab").labels_win`

Note that `jab_win` is the incremental search, so the above labels are not always used as hints.
It automatically ignore the labels that can be a part of the search query.
For example, if you hit `a` and a buffer has `abc`, then `b` never be a hint.
