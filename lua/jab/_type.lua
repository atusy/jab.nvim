---@class JabOptsCore
---@field labels string[]
---@field str string
---@field label string
---@field instant boolean
---@field kind JabKind

---@class JabOpts: JabOptsCore
---@field win number?
---@field buf number?
---@field labels string[]?
---@field kind JabKind?

---@class JabMatch
---@field row number
---@field col_start number
---@field col_end number
---@field label string
---@field col_label number?
---@field width_label number?

---@alias JabKind "f" | "F" | "t" | "T" | "window"
---@alias JabFun fun(opts: JabOpts | nil): string?
---@alias JabMotionFun fun(opts: JabOpts): string?
