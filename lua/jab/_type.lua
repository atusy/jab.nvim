---@class JabOpts
---@field labels string[]?
---@field str string
---@field label string
---@field instant boolean

---@class JabMatch
---@field row number
---@field col_start number
---@field col_end number
---@field label string

---@alias JabKind "f" | "F" | "t" | "T" | "window"
---@alias JabFun fun(kind: JabKind, labels: string[]?, opts: JabOpts?): string?
---@alias JabMotionFun fun(labels: string[]?): string?
