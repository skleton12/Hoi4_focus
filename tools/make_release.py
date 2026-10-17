"""시험판 zip 을 만든다.

    python3 tools/make_release.py

releases/gibon_jungjeom_<버전>.zip 에 모드 폴더, 바깥 .mod 파일, 설치 파일(packaging/)을 담는다.
버전은 mod/gibon_jungjeom/descriptor.mod 의 version 을 쓴다.
"""
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOD = ROOT / "mod" / "gibon_jungjeom"
PACK = ROOT / "packaging"


def main():
    version = re.search(r'version="([^"]+)"', (MOD / "descriptor.mod").read_text(encoding="utf-8")).group(1)
    out = ROOT / "releases" / f"gibon_jungjeom_{version}.zip"
    out.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(ROOT / "mod" / "gibon_jungjeom.mod", "gibon_jungjeom.mod")
        for p in sorted(MOD.rglob("*")):
            if p.is_file():
                z.write(p, p.relative_to(MOD.parent))
        z.write(PACK / "install.bat", "install.bat")
        z.write(PACK / "install.ps1", "install.ps1")
        # 메모장에서 깨지지 않게 BOM + CRLF
        text = (PACK / "설치방법.txt").read_text(encoding="utf-8-sig").replace("\r\n", "\n").replace("\n", "\r\n")
        z.writestr("설치방법.txt", "﻿" + text)
    print(f"{out.relative_to(ROOT)}  {out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
