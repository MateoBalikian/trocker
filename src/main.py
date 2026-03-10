import sys
import os
from PySide6.QtGui import QGuiApplication, QFontDatabase, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from modules.projects_manager import ProjectsManager
from modules.videos_manager import VideosManager

BASE_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS_DIR  = os.path.join(BASE_DIR, "fonts")
QML_MAIN   = os.path.join(BASE_DIR, "src", "qml", "main.qml")
ICON_PATH  = os.path.join(BASE_DIR, "assets", "trocker.ico")
PROJ_DIR   = os.path.join(BASE_DIR, "projects")

app = QGuiApplication(sys.argv)

for font_file in os.listdir(FONTS_DIR):
    if font_file.endswith((".ttf", ".otf")):
        QFontDatabase.addApplicationFont(os.path.join(FONTS_DIR, font_file))

app.setWindowIcon(QIcon(ICON_PATH))

projects_manager = ProjectsManager(PROJ_DIR)
videos_manager   = VideosManager()

engine = QQmlApplicationEngine()
engine.rootContext().setContextProperty("projectsManager", projects_manager)
engine.rootContext().setContextProperty("videosManager",   videos_manager)
engine.load(QML_MAIN)

if not engine.rootObjects():
    print(f"[ERROR] Failed to load QML: {QML_MAIN}", file=sys.stderr)
    sys.exit(1)

sys.exit(app.exec())
