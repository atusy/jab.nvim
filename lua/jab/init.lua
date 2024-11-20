---@class JabModule
---@field jab JabFun
---@field jab_win JabMotionFun
---@field f JabMotionFun
---@field F JabMotionFun
---@field t JabMotionFun
---@field T JabMotionFun
---@field namespaces number[] 1 and 2 for labelling, and 3 for backdrop
---@field cache {opts: JabOpts?, namespace: number}
---@field clear fun(buf: number?, namespaces: number[]?): nil
local M = {
	namespaces = {
		vim.api.nvim_create_namespace("jab-match1"),
		vim.api.nvim_create_namespace("jab-match2"),
		vim.api.nvim_create_namespace("jab-backdrop"),
	},
	cache = { opts = nil, namespace = 1 },
}

function M.clear(buf, namespaces)
	for _, ns in ipairs(namespaces or M.namespaces) do
		vim.api.nvim_buf_clear_namespace(buf or 0, ns, 0, -1)
	end
	vim.cmd.redraw()
end

local function backdrop(row_start, row_end, col_start, col_end)
	vim.api.nvim_buf_set_extmark(0, M.namespaces[3], row_start, col_start, {
		end_row = row_end,
		end_col = col_end,
		hl_group = "comment",
	})
end

local function _generate_kensaku_query(pat)
	if pat:match("[0-9A-Z]") then
		return pat, true
	end
	local str = pat
	local query = ""
	for _ = 1, #str do
		local left, right = string.find(str, " +", 0, false)
		if left == nil then
			return query .. vim.fn["kensaku#query"](str)
		end
		if left > 1 then
			query = query .. vim.fn["kensaku#query"](string.sub(str, 1, left - 1))
		end
		query = query .. string.rep([[\(\s\|　\)]], right - left + 1)
		str = string.sub(str, right + 1)
	end
	return query, false
end

local function generate_kensaku_query(pat, ignore_case)
	local query = _generate_kensaku_query(pat)
	if ignore_case then
		query = [[\c]] .. query
	end
	return query
end

---@param char string
---@param ignore_case boolean
---@return fun(line: string, init: number): {[1]: number, [2]: number} | nil
local function generate_finder(char, ignore_case)
	local ok, query = pcall(generate_kensaku_query, char, ignore_case)
	if not ok then
		return function(line, init)
			local idx = line:find(char, init, true)
			if idx == nil then
				return nil
			end
			-- 0-based
			return { idx - 1, idx + string.len(char) - 2 }
		end
	end
	local regex = vim.regex(query)
	return function(line, init)
		local i, j = regex:match_str(string.sub(line, init))
		if i == nil then
			return nil
		end
		return { i + init - 1, j + init - 1 }
	end
end

local regex_lastchar = vim.regex([[.$]])

---@param str string
---@param reverse boolean
---@param labels string[]
---@return JabMatch[]
local function find_inline(str, reverse, labels)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1]
	local row = cursor[1]
	local col = cursor[2] + 1
	local col_start = reverse and 1 or col
	local col_end = reverse and col or #line

	-- backdrop
	backdrop(row - 1, row - 1, reverse and 0 or col_start, col_end)

	local matches = {}
	local find = generate_finder(str, false)
	local pos = col_start
	while pos <= col_end and #matches < #labels do
		local found = find(line, pos)
		if found == nil then
			break
		end
		pos = found[2] + 1
		local match = {
			row = row,
			col_start = found[1],
			col_end = found[2],
			label = labels[#matches + 1],
		} ---@type JabMatch
		if reverse then
			if pos < col_end then
				table.insert(matches, 1, match)
			end
		elseif found[1] + 1 ~= col_start then
			table.insert(matches, match)
		end
	end
	return matches
end

---@param matches JabMatch[]
local function mark_matches(matches)
	-- suppress flickers by switching namespaces
	local ns1, ns2 = M.namespaces[1], M.namespaces[2]
	local ns = ns1
	local used_ns = ns2
	if M.cache.namespace == 1 then
		ns = ns2
		used_ns = ns1
		M.cache.namespace = 2
	else
		M.cache.namespace = 1
	end
	for _, match in ipairs(matches) do
		local virt_text = { { match.label, "Error" } }
		local padding = match.col_label
			and match.width_label
			and string.rep(" ", match.width_label - vim.fn.strdisplaywidth(match.label))
		if padding then
			table.insert(virt_text, 1, { padding, "Normal" })
		end

		vim.api.nvim_buf_set_extmark(0, ns, match.row - 1, match.col_label or match.col_start, {
			end_row = match.row - 1,
			end_col = match.col_end,
			virt_text = virt_text,
			virt_text_pos = "overlay",
			hl_group = "CurSearch",
		})
	end
	M.clear(0, { used_ns })
	vim.cmd.redraw()
end

---@param locs JabMatch[]
local function _select_label(locs)
	mark_matches(locs)
	return vim.fn.getcharstr()
end

---@param locs JabMatch[]
local function select_label(locs)
	local ok, label = pcall(_select_label, locs)
	if not ok then
		vim.notify(label)
	end
	return ok and label or nil
end

---@param str string
---@param top number
---@param lines string[]
---@param labels string[]
---@param previous_matches JabMatch[]
---@return JabMatch[]
local function find_window(str, top, lines, labels, previous_matches)
	local positioned_labels = {} ---@type table<number, table<number, string>>
	for _, match in ipairs(previous_matches) do
		if not positioned_labels[match.row] then
			positioned_labels[match.row] = {}
		end
		positioned_labels[match.row][match.col_start] = match.label
	end
	local available_labels = {}
	for _, v in ipairs(labels) do
		available_labels[v] = true
	end
	local matches = {}
	local find = generate_finder(str, true)
	for i, line in ipairs(lines) do
		local row = top + i
		local pos = 1
		local n = #line
		while pos <= n and #matches < #labels do
			local found = find(line, pos)
			if found == nil then
				break
			end
			local label = positioned_labels[row] and positioned_labels[row][found[1]]
			if not label or generate_finder(str .. label, true)(line, pos) then
				label = "" -- decide later
			end
			available_labels[label] = nil

			local text_left = string.sub(line, 1, found[1])
			local i1, i2 = regex_lastchar:match_str(text_left)
			local col_label = i1 or found[1]
			local width_label = i1 and vim.fn.strdisplaywidth(string.sub(line, i1 + 1, i2))

			local match = {
				row = row,
				col_start = found[1],
				col_end = found[2],
				label = label,
				col_label = col_label,
				width_label = width_label,
			} ---@type JabMatch
			table.insert(matches, match)
			pos = found[2] + 1
		end
	end

	local remaining_labels = {}
	for _, v in pairs(labels) do
		if available_labels[v] then
			table.insert(remaining_labels, v)
		end
	end

	local valid_matches = {}
	local txt = table.concat(lines, "\n")
	for _, match in ipairs(matches) do
		if match.label == "" then
			local candidate = table.remove(remaining_labels, 1)
			while candidate do
				if string.upper(candidate) == candidate or not generate_finder(str .. candidate, true)(txt, 1) then
					match.label = candidate
					table.insert(valid_matches, match)
					break
				end
				candidate = table.remove(remaining_labels, 1)
			end
		else
			table.insert(valid_matches, match)
		end
	end
	return valid_matches
end

---@param matches JabMatch[]
---@param label string?
---@return JabMatch | nil, string | nil
local function select_match(matches, label)
	if not matches or #matches == 0 then
		return nil, nil
	end
	label = label or select_label(matches)

	if not label then
		return nil, nil
	end

	for _, match in pairs(matches) do
		if match.label == label then
			return match, label
		end
	end

	return nil, label
end

local jumpto = nil

---@type JabFun
function M._jab(kind, labels, opts)
	kind = kind or "f"
	labels = labels or (opts and opts.labels)
	opts = opts or {}
	if jumpto ~= nil then
		vim.api.nvim_win_set_cursor(0, jumpto)
		jumpto = nil
		return
	end

	local match ---@type JabMatch?
	local str = opts.str or vim.fn.getcharstr()
	local reverse = kind == "F" or kind == "T"
	if kind == "window" then
		local win = vim.api.nvim_get_current_win()
		local wininfo = vim.fn.getwininfo(win)
		local buf, top, bot = wininfo[1].bufnr, wininfo[1].topline - 1, wininfo[1].botline
		local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
		local previous_matches = {} ---@type JabMatch[]
		backdrop(top, bot - 1, 1, #lines[#lines])
		while true do
			local matches = find_window(str, top, lines, labels, previous_matches)
			local label
			match, label = select_match(matches, opts.label)
			if not label then
				return
			end
			if match then
				break
			end
			str = str .. label -- if no match, assume label as part of the search string
			previous_matches = matches
		end
	else
		local matches = find_inline(str, reverse, labels)
		if #matches == 1 then
			match = matches[1]
		else
			match, _ = select_match(matches, opts.label)
		end
	end
	if not match then
		return
	end

	local mode = vim.api.nvim_get_mode().mode
	local operator_pending = mode == "no"
	if not match then
		if operator_pending then
			return "<Esc>"
		end
		return ""
	end
	local offsets = { f = 0, F = 0, t = -1, T = 1, window = 0 }
	local jump_col = (kind == "f" or kind == "T") and match.col_end - 1 or match.col_start
	jump_col = jump_col + offsets[kind] + (not reverse and operator_pending and 1 or 0)

	if opts.instant then
		vim.api.nvim_win_set_cursor(0, { match.row, jump_col })
		return
	end

	jumpto = { match.row, jump_col }
	if operator_pending then
		M.cache.opts = { str = str, label = match.label, instant = true, labels = labels } ---@type JabOpts
	end
	return string.format("<cmd>lua require('jab').jab([==[%s]==], nil, require('jab').cache.opts)<cr>", kind)
end

---@type JabFun
function M.jab(kind, labels, opts)
	local ok, res = pcall(M._jab, kind, labels, opts)
	M.clear()
	if not ok then
		if res then
			error(res, vim.log.levels.ERROR)
		end
		error()
	end
	return res
end

---@param x string
---@return string[]
local function string2labels(x)
	local labels = {}
	for i = 1, #x do
		table.insert(labels, string.sub(x, i, i))
	end
	return labels
end
local labels_f = string2labels([[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()[]`'=-{}~"+_]])
local labels_win =
	string2labels([[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_]])

M.f = function(labels)
	return M.jab("f", labels or labels_f)
end

M.t = function(labels)
	return M.jab("t", labels or labels_f)
end

M.F = function(labels)
	return M.jab("F", labels or labels_f)
end

M.T = function(labels)
	return M.jab("T", labels or labels_f)
end

M.jab_win = function(labels)
	return M.jab("window", labels or labels_win)
end

return M
