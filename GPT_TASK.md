# GPT 작업 지시서 — PC 에서 모드 복구·설치·확인

> 이 문서는 Claude 가 쓴다. GPT 는 사용자 PC(Windows)에서 아래 순서대로 하고, 결과를 이 저장소에 커밋한다.
> 저장소: `skleton12/Hoi4_focus` · 브랜치: `main`

## 지금 상황 (2026-10-18)

- 0.4.7 설치 파일이 런처에서 **켜져 있던** `mod\gibon_jungjeom` 을 `mod\_gj_backup` 으로 옮겨 버려서,
  게임에 **바닐라 기본 중점**이 나온다. (Claude 실수)
- 0.4.8 설치 파일은 아무것도 옮기거나 지우지 않고, `_gj_backup` 에 간 것을 되돌리고,
  이 모드가 깔린 폴더(`gibon_jungjeom`, `new_focus` 등)를 모두 새 내용으로 갱신한다.
- 사용자 PC 모드 폴더: `C:\Users\user\Documents\Paradox Interactive\Hearts of Iron IV\mod`
  (`new_focus` 도 깔려 있다)

## 할 일

게임과 런처를 끈 상태에서, 저장소 폴더에서 PowerShell 로:

```powershell
git pull
# 1) 고치기 전 상태 기록 (읽기만 함)
powershell -ExecutionPolicy Bypass -File .\tools\Report-ModState.ps1
copy .\reports\mod-state.txt .\reports\mod-state-before.txt

# 2) 복구 + 설치 (zip 의 install.bat 과 같은 스크립트)
powershell -ExecutionPolicy Bypass -File .\packaging\install.ps1

# 3) 고친 뒤 상태 기록
powershell -ExecutionPolicy Bypass -File .\tools\Report-ModState.ps1
```

그다음:

4. 런처를 켜서 플레이세트에 「기본 중점 변경 모드」(또는 `- new_focus 독립시험`)가 **하나만** 켜져 있는지 확인한다.
   둘 다 있으면 하나만 켠다. 꺼져 있으면 켠다.
5. 런처에서 실행 → **새 게임** → 고유 트리가 없는 나라(예: 코스타리카, 알바니아)로 중점 화면을 연다.
6. 확인할 것:
   - [ ] 바닐라가 아니라 우리 트리(산업·군사·정치·외교·괴뢰국 갈래, 약 1000칸)가 나온다
   - [ ] 중점에 마우스를 올리면 설명 끝에 회색 **(v0.4.8)** 이 보인다
   - [ ] % 효과 칸 툴팁이 「산업 개혁: 공장 생산량 +5%」처럼 노랑·초록으로 나온다 (흰 글씨 「설계 효과」가 없다)
   - [ ] % 효과 칸 하나를 완료(콘솔 `focus.autocomplete` 후 칸 클릭)하면 국가 정신에 「산업 개혁」 등이 생긴다
7. 게임을 끄고 `tools\Report-ModState.ps1` 을 한 번 더 돌려 error.log 줄을 담는다.

## 결과 남기기

- `reports/mod-state-before.txt`, `reports/mod-state.txt` 를 커밋한다.
- 이 파일 맨 아래 「결과」에 6번 체크 결과와 이상한 점을 적어 커밋한다. 스크린샷이 있으면 `reports/` 에.
- **하지 말 것:** `mod/gibon_jungjeom/` 안 파일을 손으로 고치지 않는다(생성기가 덮어쓴다).
  사용자 PC 의 모드 폴더를 지우거나 옮기지 않는다. 문제가 있으면 기록만 하고 Claude 에게 넘긴다.

## 결과

(GPT 가 채운다)
