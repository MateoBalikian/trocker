import os
import shutil
from PySide6.QtCore import QObject, Property, Signal, Slot


class VideosManager(QObject):
    videosChanged       = Signal()
    activeVideoChanged  = Signal()
    activeProjectChanged = Signal()

    VIDEO_EXTS = {".mp4", ".avi", ".mov", ".mkv", ".webm"}

    def __init__(self, parent=None):
        super().__init__(parent)
        self._project_path = ""
        self._project_name = ""
        self._active_video = ""
        self._duration_cache: dict[str, str] = {}
        self._thumbnail_cache: dict[str, str] = {}

    # ── Internal helpers ───────────────────────────────────────────────────────

    def _get_duration(self, path: str) -> str:
        if path in self._duration_cache:
            return self._duration_cache[path]
        dur = "--:--"
        try:
            import cv2
            cap = cv2.VideoCapture(path)
            fps = cap.get(cv2.CAP_PROP_FPS)
            frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)
            cap.release()
            if fps > 0 and frames > 0:
                total = int(frames / fps)
                dur = f"{total // 60}:{total % 60:02d}"
        except Exception:
            pass
        self._duration_cache[path] = dur
        return dur

    def _get_thumbnail(self, path: str, name: str) -> str:
        if path in self._thumbnail_cache:
            return self._thumbnail_cache[path]
        result = ""
        try:
            import cv2
            thumb_dir = os.path.join(self._project_path, ".thumbnails")
            os.makedirs(thumb_dir, exist_ok=True)
            base = os.path.splitext(name)[0]
            thumb_path = os.path.join(thumb_dir, base + ".jpg")
            if not os.path.exists(thumb_path):
                cap = cv2.VideoCapture(path)
                cap.set(cv2.CAP_PROP_POS_MSEC, 1000)
                ret, frame = cap.read()
                cap.release()
                if ret:
                    cv2.imwrite(thumb_path, frame)
            if os.path.exists(thumb_path):
                result = thumb_path.replace("\\", "/")
        except Exception:
            pass
        self._thumbnail_cache[path] = result
        return result

    # ── Qt API ─────────────────────────────────────────────────────────────────

    @Slot(str)
    def setProject(self, path: str):
        self._project_path = path
        self._active_video = ""
        self._duration_cache.clear()
        self._thumbnail_cache.clear()
        self.videosChanged.emit()
        self.activeVideoChanged.emit()
        self.activeProjectChanged.emit()

    @Slot(str)
    def setProjectName(self, name: str):
        self._project_name = name
        self.activeProjectChanged.emit()

    @Property(str, notify=activeProjectChanged)
    def activeProjectName(self):
        return self._project_name

    @Property(str, notify=activeProjectChanged)
    def activeProjectPath(self):
        return self._project_path

    @Property(str, notify=activeVideoChanged)
    def activeVideoPath(self):
        if not self._active_video or not self._project_path:
            return ""
        return os.path.join(self._project_path, self._active_video).replace("\\", "/")

    @Property(list, notify=videosChanged)
    def videos(self):
        if not self._project_path or not os.path.isdir(self._project_path):
            return []
        result = []
        for name in sorted(os.listdir(self._project_path)):
            if os.path.splitext(name)[1].lower() not in self.VIDEO_EXTS:
                continue
            full = os.path.join(self._project_path, name)
            result.append({
                "name":      name,
                "path":      full.replace("\\", "/"),
                "duration":  self._get_duration(full),
                "isActive":  name == self._active_video,
                "thumbnail": self._get_thumbnail(full, name),
            })
        return result

    @Property(str, notify=activeVideoChanged)
    def activeVideo(self):
        return self._active_video

    @Slot(str, result=bool)
    def addVideo(self, src_path: str) -> bool:
        # Strip file:// URL prefix (from QML FileDialog)
        for prefix in ("file:///", "file://"):
            if src_path.startswith(prefix):
                src_path = src_path[len(prefix):]
                break
        src_path = src_path.replace("/", os.sep)
        if not os.path.isfile(src_path):
            return False
        name = os.path.basename(src_path)
        dst = os.path.join(self._project_path, name)
        if os.path.exists(dst):
            return False
        shutil.copy2(src_path, dst)
        self.videosChanged.emit()
        return True

    @Slot(str, str, result=bool)
    def renameVideo(self, old_name: str, new_name: str) -> bool:
        new_name = new_name.strip()
        if not new_name or old_name == new_name:
            return False
        # Preserve extension if user omitted it
        if not os.path.splitext(new_name)[1]:
            new_name += os.path.splitext(old_name)[1]
        old_path = os.path.join(self._project_path, old_name)
        new_path = os.path.join(self._project_path, new_name)
        if not os.path.exists(old_path) or os.path.exists(new_path):
            return False
        os.rename(old_path, new_path)
        # Evict cache entries for the old path
        self._duration_cache.pop(old_path, None)
        self._thumbnail_cache.pop(old_path, None)
        if self._active_video == old_name:
            self._active_video = new_name
            self.activeVideoChanged.emit()
        self.videosChanged.emit()
        return True

    @Slot(str)
    def deleteVideo(self, name: str):
        path = os.path.join(self._project_path, name)
        if not os.path.isfile(path):
            return
        os.remove(path)
        # Remove cached thumbnail
        thumb = os.path.join(
            self._project_path, ".thumbnails",
            os.path.splitext(name)[0] + ".jpg"
        )
        if os.path.exists(thumb):
            os.remove(thumb)
        self._duration_cache.pop(path, None)
        self._thumbnail_cache.pop(path, None)
        if self._active_video == name:
            self._active_video = ""
            self.activeVideoChanged.emit()
        self.videosChanged.emit()

    @Slot(str)
    def setActive(self, name: str):
        self._active_video = name
        self.activeVideoChanged.emit()
        self.videosChanged.emit()

    @Slot()
    def refreshVideos(self):
        """Force a rescan of the project folder — call after tracker saves a new file."""
        self._duration_cache.clear()
        self._thumbnail_cache.clear()
        self.videosChanged.emit()
