---@class JabOpts
---@field labels string[]?
---@field str string
---@field label string
---@field instant boolean

---@alias JabKind "f" | "F" | "t" | "T" | "window"
---@alias JabMatch {[1]: number, [2]: number, [3]: number, [4]: string}
---@alias JabFun fun(kind: JabKind, labels: string[]?, opts: JabOpts?): string?
---@alias JabMotionFun fun(labels: string[]?): string?
