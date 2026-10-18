# 기본 중점 변경 모드 (HOI4)

Hearts of Iron IV 의 **기본(제네릭) 국가 중점 트리**를 새로 짠 모드다. 고유 트리가 없는 나라
(한국 계열 소국, 알바니아, 중남미 국가 등)가 이 트리를 받는다.

- 대상 게임: HOI4 1.19.3 (1.19.3.0.c01a)
- 현재 버전: 0.9.0 · 1035칸 (산업 151 · 군사 111 · 정치 606 · 외교 78 · 괴뢰국/종주국/독립 89)
- 런처 이름: 「기본 중점 개편」 (0.5.1 부터. 예전 이름 「기본 중점 변경 모드」)

## 내려받아 설치하기

0. 가장 간단한 방법: zip 안의 `gibon_jungjeom` 폴더와 `gibon_jungjeom.mod` 를 `문서\Paradox Interactive\Hearts of Iron IV\mod` 에 덮어쓰고, 런처에서 「기본 중점 개편」 하나만 켠다.
1. [`releases/`](releases/) 에서 최신 zip 을 받아 **오른쪽 클릭 → 압축 풀기**로 푼다(zip 안에서 바로 실행하면 안 된다).
2. `install.bat` 더블클릭 → 문서\Paradox Interactive\Hearts of Iron IV\mod 에 복사된다.
   이 모드가 이미 깔린 폴더(`gibon_jungjeom`, `new_focus` 등)는 지금 내용을 `mod\_gj_backup\<폴더>_<시각>` 에 복사해 둔 뒤 새 버전으로 바꾼다.
   문제가 있으면 zip 의 `상태보고.bat` 을 실행하고 `mod-state.txt` 를 붙여 준다.
   같은 이름의 다른 `.mod` 가 있으면 `mod\_gj_backup` 으로 옮긴다(이름이 겹치면 모드가 안 켜진다).
3. 런처에서 모드를 켜고 실행.

## 폴더

| 경로 | 내용 |
|---|---|
| `design/generic_tree/data/*.json` | 설계 데이터 (갈래 · 소갈래 · 포커스 이름 · 효과 문구) |
| `design/generic_tree/build_mod.py` | 설계 → 모드 파일 생성기 |
| `design/generic_tree/check.py` | 설계 데이터 검사 |
| `design/generic_tree/render.py` | 트리 그림 → `design/generic_tree/img/` |
| `design/generic_tree/REPORT.md` | 변경 내역 · 확인 결과 |
| `design/generic_tree/EFFECT_STATUS.md` | 효과 작동 현황 (문구만 있는 효과 목록) |
| `design/generic_tree/AGENTS.md`, `SPEC.md` | 작업 규칙 · 데이터 형식 |
| `mod/gibon_jungjeom/`, `mod/gibon_jungjeom.mod` | 생성된 모드 (직접 고치지 말고 생성기로 만든다) |
| `tools/validate.py` | 모드 문법·참조 검사 |
| `tools/Install-Mod.ps1`, `Check-Hoi4Mod.ps1`, `Test-Mod.ps1` | Windows 설치 · 진단 · 시험 |
| `tools/Report-ModState.ps1` | PC 상태 보고서(읽기만) → `reports/mod-state.txt` |
| `packaging/install.ps1` | 설치(zip 의 install.bat). 저장소에서 바로 돌려도 된다 |
| `tools/make_release.py`, `packaging/` | 시험판 zip 만들기 |

## 고치는 순서

```bash
# 1. data/*.json 수정
python3 design/generic_tree/check.py        # 설계 검사 (오류 0)
python3 design/generic_tree/build_mod.py    # mod/gibon_jungjeom 다시 생성
python3 tools/validate.py                   # 모드 검사 (오류 0)
python3 tools/test_focus_effects.py          # 효과 생성 회귀 검사
python3 design/generic_tree/render.py       # 그림 갱신 (Pillow 필요)
# 2. 배포할 때: descriptor 두 곳의 version 올리고
python3 tools/make_release.py               # releases/gibon_jungjeom_<버전>.zip
```

Claude 와 GPT(Codex) 가 이 저장소의 파일로 함께 작업한다. **GPT 의 PC 작업 순서는 [`GPT_TASK.md`](GPT_TASK.md).** 규칙은 `design/generic_tree/AGENTS.md`.
