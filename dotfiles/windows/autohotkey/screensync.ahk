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
;
; Any access to an SSHFS drive whose connection died (server rebooted, sleep)
; can block for good, so each copy runs in a hidden cmd process: after TIMEOUT
; seconds its server is reported as not responding, instead of the whole
; script freezing.

TARGETS := [
    {host: "rhskl2", dir: "R:\home\toscm\pictures\screenshots"},
    {host: "r4", dir: "S:\home\tschmidt\pictures\screenshots"},
]
REMOTE_DIR := "~/pictures/screenshots/"
TIMEOUT := 10

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

; Host -> its copy job that timed out, until that process has really ended.
; Such a host is reported as not reachable right away, without another job
; that would just get stuck as well.
stuck := Map()
batches := []

; Starts one copy job per target on a mounted drive; Collect() reports them
; all in one notification once each has finished or timed out.
Sync(path, name) {
    drives := DriveGetList()  ; Does not touch the drives, so cannot hang.
    batch := {name: name, jobs: []}
    for t in TARGETS {
        job := {host: t.host, result: "", started: A_TickCount, process: 0}
        if !InStr(drives, SubStr(t.dir, 1, 1))
            job.result := Remembered(SubStr(t.dir, 1, 1)) ? "unreachable" : "unmounted"
        else if stuck.Has(t.host)
            job.result := "unreachable"
        else {
            ; Exit code 3: folder missing; 1: copy failed; 0: copied.
            cmd := A_ComSpec ' /d /c if not exist "' t.dir '\" (exit 3) else copy /y "'
                 . path '" "' t.dir "\" name '" >nul'
            try
                job.process := StartHidden(cmd)
            catch
                job.result := "failed"
        }
        batch.jobs.Push(job)
    }
    batches.Push(batch)
    SetTimer(Collect, 200)
}

; Whether the drive letter is a remembered network drive (HKCU\Network). A
; dead SSHFS drive can vanish from the drive list while its mapping stays.
Remembered(letter) {
    try return RegRead("HKCU\Network\" letter, "RemotePath") != ""
    return false
}

Collect() {
    global batches
    left := []
    for batch in batches {
        done := true
        for job in batch.jobs {
            if job.result = ""
                CheckJob(job)
            if job.result = ""
                done := false
            else if job.result = "copied" && !batch.HasOwnProp("clipped") {
                ; Paste-ready as soon as one copy is there.
                A_Clipboard := REMOTE_DIR batch.name
                batch.clipped := true
            }
        }
        if done
            Report(batch)
        else
            left.Push(batch)
    }
    batches := left
    if !batches.Length
        SetTimer(Collect, 0)
}

; Sets job.result to "copied", "failed" or "unreachable" once known. The
; folder missing on a mounted drive means the connection is dead (a dead
; SSHFS drive either blocks or answers that nothing is there).
CheckJob(job) {
    h := job.process
    if DllCall("WaitForSingleObject", "Ptr", h, "UInt", 0) = 0 {
        code := 1
        DllCall("GetExitCodeProcess", "Ptr", h, "UInt*", &code)
        DllCall("CloseHandle", "Ptr", h)
        job.result := code = 0 ? "copied" : code = 3 ? "unreachable" : "failed"
    } else if A_TickCount - job.started > TIMEOUT * 1000 {
        ; Usually stuck in the file system for good; try to end it anyway.
        DllCall("TerminateProcess", "Ptr", h, "UInt", 1)
        job.result := "unreachable"
        stuck[job.host] := job
        SetTimer(ReleaseWhenGone.Bind(job), 5000)
    }
}

ReleaseWhenGone(job) {
    if DllCall("WaitForSingleObject", "Ptr", job.process, "UInt", 0) != 0
        return
    SetTimer(, 0)
    DllCall("CloseHandle", "Ptr", job.process)
    if stuck.Get(job.host, "") = job
        stuck.Delete(job.host)
}

Report(batch) {
    copied := [], problems := []
    for job in batch.jobs {
        switch job.result {
            case "copied": copied.Push(job.host)
            case "failed": problems.Push("copying to " job.host " failed")
            case "unreachable": problems.Push(job.host " not reachable")
        }
    }
    if copied.Length {
        msg := "Copied to " Join(copied) ", path in clipboard:`n" REMOTE_DIR batch.name
        if problems.Length
            msg .= "`n(" Join(problems) ")"
        TrayTip(msg, "screensync", (problems.Length ? "Icon!" : "Iconi") " Mute")
        if !problems.Length
            SetTimer(HideTrayTip, -3000)
    } else if problems.Length
        TrayTip(Join(problems) ", " batch.name " not copied", "screensync", "Iconx")
    else
        TrayTip("No server drive mounted, " batch.name " not copied", "screensync", "Icon! Mute")
}

; Runs cmd without a window and returns its process handle (to be closed by
; the caller). Unlike Run(), this keeps the handle, so the exit code can be read.
StartHidden(cmd) {
    si := Buffer(A_PtrSize = 8 ? 104 : 68, 0)
    NumPut("UInt", si.Size, si)
    pi := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    if !DllCall("CreateProcessW", "Ptr", 0, "Str", cmd, "Ptr", 0, "Ptr", 0, "Int", false,
                "UInt", 0x08000000, "Ptr", 0, "Ptr", 0, "Ptr", si, "Ptr", pi)  ; CREATE_NO_WINDOW
        throw OSError()
    DllCall("CloseHandle", "Ptr", NumGet(pi, A_PtrSize, "Ptr"))
    return NumGet(pi, 0, "Ptr")
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
