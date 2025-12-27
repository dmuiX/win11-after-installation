#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Universal Shortcuts ---
$!x::Send("^x")         ; Alt+X -> Ctrl+X (Cut)
$!c::Send("^c")         ; Alt+C -> Ctrl+C (Copy)
$!v::Send("^v")         ; Alt+V -> Ctrl+V (Paste)
$!s::Send("^s")         ; Alt+S -> Ctrl+S (Save)
$!a::Send("^a")         ; Alt+A -> Ctrl+A (Select All)
$!z::Send("^z")         ; Alt+Z -> Ctrl+Z (Undo)
$!+z::Send("^y")        ; Alt+Shift+Z -> Ctrl+Y (Redo)
$!w::Send("^w")         ; Alt+W -> Ctrl+W (Close Window/Tab)
$!f::Send("^f")         ; Alt+F -> Ctrl+F (Find)
$!n::Send("^n")         ; Alt+N -> Ctrl+N (New)
$!q::Send("!{f4}")      ; Alt+Q -> Alt+F4 (Quit App)
$!r::Send("^{f5}")      ; Alt+R -> Ctrl+F5 (Hard Refresh)
$!m::Send("#d")         ; Alt+D -> Win+D (Show Desktop / Minimize All)
$!`::Send("{Alt Down}{Shift Down}{Tab}{Shift Up}") ; Alt+` -> Cycle backwards through windows of an app

; --- Quick Switch Tab shortcuts ---
$!1::Send("^1")
$!2::Send("^2")
$!3::Send("^3")
$!4::Send("^4")
$!5::Send("^5")
$!6::Send("^6")
$!7::Send("^7")
$!8::Send("^8")
$!9::Send("^9")
$!0::Send("^0")

; --- Browser/Tab-based App shortcuts ---
$!t::Send("^t")         ; Alt+T -> Ctrl+T (New Tab)
$!+t::Send("^+t")       ; Alt+Shift+T -> Re-open Closed Tab (Undo Close)
$!+]::Send("^{Tab}")   ; Alt+] -> Ctrl+Tab (Next Tab)
$!+[::Send("^+{Tab}")  ; Alt+[ -> Ctrl+Shift+Tab (Previous Tab)
$!l::Send("^l")         ; Alt+L -> Focus Address Bar

; --- Text Navigation and Selection ---
$!Left::Send("{Home}")
$!Right::Send("{End}")
$!Up::Send("^{Home}")
$!Down::Send("^{End}")

$!+Left::Send("+{Home}")
$!+Right::Send("+{End}")
$!+Up::Send("^+{Home}")
$!+Down::Send("^+{End}")

#Left::Send("^{Left}")
#Right::Send("^{Right}")
#+Left::Send("^+{Left}")
#+Right::Send("^+{Right}")
#BS::Send("^{BS}")     ; Win+Backspace -> Ctrl+Backspace (Delete previous word)
