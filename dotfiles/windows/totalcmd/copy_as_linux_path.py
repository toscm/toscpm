r"""Copy Windows paths to the clipboard as Linux-style paths, one per line.

Two callers:

- Total Commander, via usercmd.ini (em_CopyAsLinuxPath, bound to Alt+C):
  `pythonw.exe copy_as_linux_path.py --list %UL`, where %UL is a UTF-8 list
  file with one full path per line (the selection, or the item under the
  cursor).

- The "Copy as Linux path" entry of the Explorer context menu, registered
  by `toscpm link`: `pythonw.exe copy_as_linux_path.py <path>`.

Paths on an SSHFS-Win drive become remote paths: a root mount
(\sshfs.r\..., \sshfs.kr\...) maps the drive letter to /, a home mount
(\sshfs\..., \sshfs.k\...) maps it to ~. Every other path keeps its
drive letter and only gets forward slashes (C:\x -> C:/x, \srv\share ->
//srv/share), which Windows tools, R, Python and git all accept.
Standard library only, so any pythonw works.
"""

import ctypes
import re
import sys
from ctypes import wintypes

SSHFS_RE = re.compile(r"^\\\\sshfs(?:\.(\w+))?\\[^\\]+(\\.*)?$", re.IGNORECASE)


def drive_remote(drive):
    """UNC path mapped to `drive` ('R:'), or None if it is not a network drive."""
    buf = ctypes.create_unicode_buffer(1024)
    size = wintypes.DWORD(len(buf))
    if ctypes.windll.mpr.WNetGetConnectionW(drive, buf, ctypes.byref(size)) != 0:
        return None
    return buf.value


def linux_path(path, cache={}):
    path = path.rstrip("\\") if len(path) > 3 else path
    if len(path) < 2 or path[1] != ":":
        return path.replace("\\", "/")
    drive = path[:2].upper()
    if drive not in cache:
        cache[drive] = drive_remote(drive)
    m = SSHFS_RE.match(cache[drive] or "")
    if not m:
        return drive + path[2:].replace("\\", "/")
    flags, sub = (m.group(1) or "").lower(), m.group(2) or ""
    base = "" if "r" in flags else "~"
    rest = (sub + path[2:]).replace("\\", "/").rstrip("/")
    return base + rest if base + rest else "/"


def set_clipboard(text):
    CF_UNICODETEXT, GMEM_MOVEABLE = 13, 0x0002
    k32, u32 = ctypes.windll.kernel32, ctypes.windll.user32
    k32.GlobalAlloc.restype = wintypes.HGLOBAL
    k32.GlobalAlloc.argtypes = [wintypes.UINT, ctypes.c_size_t]
    k32.GlobalLock.restype = wintypes.LPVOID
    k32.GlobalLock.argtypes = [wintypes.HGLOBAL]
    k32.GlobalUnlock.argtypes = [wintypes.HGLOBAL]
    u32.SetClipboardData.restype = wintypes.HANDLE
    u32.SetClipboardData.argtypes = [wintypes.UINT, wintypes.HANDLE]

    data = ctypes.create_unicode_buffer(text)
    nbytes = ctypes.sizeof(data)
    handle = k32.GlobalAlloc(GMEM_MOVEABLE, nbytes)
    ctypes.memmove(k32.GlobalLock(handle), data, nbytes)
    k32.GlobalUnlock(handle)
    if not u32.OpenClipboard(None):
        raise OSError("cannot open the clipboard")
    try:
        u32.EmptyClipboard()
        u32.SetClipboardData(CF_UNICODETEXT, handle)
    finally:
        u32.CloseClipboard()


def main():
    args = sys.argv[1:]
    if args[:1] == ["--list"]:
        with open(args[1], encoding="utf-8-sig") as f:
            args = [line.rstrip("\r\n") for line in f if line.strip()]
    set_clipboard("\n".join(linux_path(p) for p in args))


if __name__ == "__main__":
    # pythonw has no console, so failures would vanish; log them instead.
    try:
        main()
    except Exception:
        import os
        import traceback
        log = os.path.join(os.environ.get("TEMP", "."), "copy_as_linux_path.log")
        with open(log, "a", encoding="utf-8") as f:
            f.write(f"argv={sys.argv!r}\n{traceback.format_exc()}\n")
        raise
