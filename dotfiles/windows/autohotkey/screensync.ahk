#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Copies each new screenshot (Snipping Tool, Win+Shift+S, Win+PrtScn) to
; ~/pictures/screenshots on the servers mounted as SSHFS drives, then puts
; that path into the clipboard, e.g. ~/pictures/screenshots/Screenshot 2026-10-22 140645.png,
; ready to paste into a shell or a claude session on the server.
; A screenshot that is overwritten (e.g. drawn into and saved again) is
; copied again. A target is skipped while its folder does not exist (drive
; not mounted).

TARGETS := ["R:\home\toscm\pictures\screenshots", "S:\home\tschmidt\pictures\screenshots"]
REMOTE_DIR := "~/pictures/screenshots/"

; The Pictures known folder (CSIDL 0x27), which may have been moved.
SOURCE := ComObject("Shell.Application").NameSpace(0x27).Self.Path "\Screenshots"

; Only files created or modified within the last RECENT seconds are looked
; at; a new or overwritten file always is, since saving it renews its time.
RECENT := 60

; Name -> "mtime|size" of the recent files: in synced as last copied, in
; pending as seen at the last poll. A file is copied once its signature has
; stayed the same for one poll, so a screenshot that is still being written
; is not copied half-done. Entries are dropped once a file is no longer recent.
synced := Map()
pending := Map()
for name, sig in RecentFiles()
    synced[name] := sig

TraySetIcon("imageres.dll", 109)
A_IconTip := "screensync: " SOURCE
A_TrayMenu.Insert("1&", "Open screenshots folder", (*) => Run(SOURCE))
A_TrayMenu.Insert("2&")
A_TrayMenu.Default := "Open screenshots folder"
A_TrayMenu.ClickCount := 1

SetTimer(Poll, 1000)

Poll() {
    recent := RecentFiles()
    for name in [synced*]
        if !recent.Has(name)
            synced.Delete(name)
    for name in [pending*]
        if !recent.Has(name)
            pending.Delete(name)
    for name, sig in recent {
        if synced.Has(name) && synced[name] = sig
            continue
        if pending.Get(name, "") != sig || SubStr(sig, -2) = "|0" {
            pending[name] := sig
            continue
        }
        pending.Delete(name)
        synced[name] := sig
        Sync(SOURCE "\" name, name)
    }
}

; Name -> "mtime|size" of the files created or modified in the last RECENT
; seconds. A file copied in keeps its old mtime but gets a new creation time.
RecentFiles() {
    files := Map()
    Loop Files SOURCE "\*.*" {
        stamp := Max(A_LoopFileTimeModified, A_LoopFileTimeCreated)
        if DateDiff(A_Now, stamp, "Seconds") <= RECENT
            files[A_LoopFileName] := A_LoopFileTimeModified "|" A_LoopFileSize
    }
    return files
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
        if !failed.Length
            SetTimer(HideTrayTip, -3000)
    }
    if failed.Length
        TrayTip("Copying " name " to " Join(failed) " failed", "screensync", "Iconx")
    else if !copied.Length
        TrayTip("No target folder reachable, " name " not copied", "screensync", "Icon! Mute")
}

; Windows 10/11 keep a tray notification on screen until it is clicked away;
; TrayTip() alone does not remove it, but briefly hiding the tray icon does.
HideTrayTip() {
    TrayTip()
    A_IconHidden := true
    Sleep(200)
    A_IconHidden := false
}

Join(list) {
    out := ""
    for item in list
        out .= (out = "" ? "" : ", ") item
    return out
}
