---@class JabOpts
---@field labels string[]?
---@field str string
---@field label string
---@field instant boolean
---@field win number?
---@field buf number?

---@class JabSearchOpts
---@field regex string

---@class JabMatch
---@field row number
---@field col_start number
---@field col_end number
---@field label string
---@field col_label number?
---@field width_label number?

---@alias JabKind "f" | "F" | "t" | "T" | "window"
---@alias JabFun fun(kind: JabKind, labels: string[]?, opts: JabOpts | JabSearchOpts | nil): string?
---@alias JabMotionFun fun(labels: string[]?): string?
