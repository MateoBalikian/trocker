import sys
import os
from PySide6.QtGui import QGuiApplication, QFontDatabase, QIcon
from PySide6.QtQml import QQmlApplicationEngine

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS_DIR = os.path.join(BASE_DIR, "fonts")
QML_MAIN = os.path.join(BASE_DIR, "src", "qml", "main.qml")
ICON_PATH = os.path.join(BASE_DIR, "assets", "trocker.ico")

app = QGuiApplication(sys.argv)

for font_file in os.listdir(FONTS_DIR):
    if font_file.endswith((".ttf", ".otf")):
        QFontDatabase.addApplicationFont(os.path.join(FONTS_DIR, font_file))

app.setWindowIcon(QIcon(ICON_PATH))

engine = QQmlApplicationEngine()
engine.load(QML_MAIN)

if not engine.rootObjects():
    print(f"[ERROR] Failed to load QML: {QML_MAIN}", file=sys.stderr)
    sys.exit(1)

sys.exit(app.exec())
