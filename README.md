# jab.nvim

Motion plugin with label-hinting supporting Japanese (migemo).

Hit jabs to where you want to go with following motions!

- incremental-search motions
- f/F/t/T-like motions

They are dot-repeatable, so you can hit as many jabs as you want.

## Recommendation

To hit jabs on Japanese characters, you need following plugins.

- https://github.com/lambdalisue/vim-kensaku
- https://github.com/vim-denops/denops.vim

## Configurations

```lua
-- incremental search
-- if vim-kensaku is available, the search is smart-case.
-- hints appear on the left of the matches if possible.
vim.keymap.set({ "n", "x", "o" }, ";", function()
	require("jab").jab_win()
end, { expr = true })

-- f-motions
-- search is always case-sensitive
-- hints appear exactly on the matches.
vim.keymap.set({ "n", "x", "o" }, "f", function()
	require("jab").f()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", function()
	require("jab").F()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", function()
	require("jab").t()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", function()
	require("jab").T()
end, { expr = true })
```

This plugin is based on my use case, so it has limited configurabilities.

Exceptionally, you can provide custome-labels like below.

```lua
vim.keymap.set({ "n", "x", "o" }, "f", function()
	require("jab").f({ "a", "b", "c" })
end, { expr = true })
```

Default labels are as follows.

- f/F/t/T: ``` abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()[]`'=-{}~"+_ ``` 
- jab_win: ``` ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_ ```

Note that `jab_win` is the incremental search, so the above labels are not always used as hints.
It automatically ignore the labels that can be a part of the search query.
For example, if you hit `a` and a buffer has `abc`, then `b` never be a hint.
