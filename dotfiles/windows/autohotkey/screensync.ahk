#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Copies each new screenshot (Snipping Tool, Win+Shift+S, Win+PrtScn) to
; ~/pictures/screenshots on the servers mounted as SSHFS drives, then puts
; that path into the clipboard, e.g. ~/pictures/screenshots/Screenshot 2026-10-22 140645.png,
; ready to paste into a shell or a claude session on the server.
; A target is skipped while its folder does not exist (drive not mounted).

TARGETS := ["R:\home\toscm\pictures\screenshots", "S:\home\tschmidt\pictures\screenshots"]
REMOTE_DIR := "~/pictures/screenshots/"

; The Pictures known folder (CSIDL 0x27), which may have been moved.
SOURCE := ComObject("Shell.Application").NameSpace(0x27).Self.Path "\Screenshots"

; Name -> size seen at the last poll, for files not yet copied. A file is
; copied once its size has stayed the same for one poll, so a screenshot
; that is still being written is not copied half-done.
pending := Map()
known := Map()
Loop Files SOURCE "\*.*"
    known[A_LoopFileName] := true

TraySetIcon("imageres.dll", 109)
A_IconTip := "screensync: " SOURCE
A_TrayMenu.Insert("1&", "Open screenshots folder", (*) => Run(SOURCE))
A_TrayMenu.Insert("2&")
A_TrayMenu.Default := "Open screenshots folder"
A_TrayMenu.ClickCount := 1

SetTimer(Poll, 1000)

Poll() {
    Loop Files SOURCE "\*.*" {
        name := A_LoopFileName
        if known.Has(name)
            continue
        size := A_LoopFileSize
        if !pending.Has(name) || pending[name] != size || size = 0 {
            pending[name] := size
            continue
        }
        pending.Delete(name)
        known[name] := true
        Sync(A_LoopFileFullPath, name)
    }
}

Sync(path, name) {
    copied := [], failed := []
    for dir in TARGETS {
        if !DirExist(dir)
            continue
        try {
            FileCopy(path, dir "\" name, true)
            copied.Push(SubStr(dir, 1, 2))
        } catch
            failed.Push(SubStr(dir, 1, 2))
    }
    if copied.Length {
        A_Clipboard := REMOTE_DIR name
        TrayTip("Copied to " Join(copied) ", path in clipboard:`n" REMOTE_DIR name,
                "screensync", "Iconi Mute")
    }
    if failed.Length
        TrayTip("Copying " name " to " Join(failed) " failed", "screensync", "Iconx")
    else if !copied.Length
        TrayTip("No target folder reachable, " name " not copied", "screensync", "Icon! Mute")
}

Join(list) {
    out := ""
    for item in list
        out .= (out = "" ? "" : ", ") item
    return out
}
