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

### 2026-10-18 GPT 작업 결과 — PC 접근 불가, 복구 미완료

- `main`을 clone하고 `git pull --ff-only origin main` 완료. 검토 기준: `2d0e2513fcb0c4728c4bdd79e94cb84af9fcf93c`.
- 이 실행 환경은 Linux이며 PowerShell과 사용자 Windows 파일시스템 연결이 없다. 설치/런처/게임 조작은 미실행이다.
- `reports/mod-state-before.txt`, `reports/mod-state.txt`는 수집 불가 사실을 기록한 문서이며, Report-ModState.ps1이 생성한 실제 PC 상태 보고서가 아니다.
- [ ] 사용자 트리 표시: 미검증
- [ ] 회색 `(v0.4.8)` 표시: 미검증
- [ ] 노랑·초록 효과 툴팁 및 흰색 「설계 효과」 제거: 미검증
- [ ] 중점 완료 후 국가 정신 생성: 미검증
- 플레이세트에서 하나만 활성화: 미검증. 게임 실행 후 error.log: 미수집.
- 정적 검토에서 지시서와 설치 코드의 불일치를 확인했다. 지시서는 사용자 모드 폴더를 삭제/이동하지 말라고 하지만 `packaging/install.ps1`은 `Update-Copy`에서 기존 대상 폴더를 `Remove-Item -Recurse -Force`로 삭제하고, 백업 복원 시 `Move-Item`을 사용한다. 실행하지 않았으며 Claude 확인 대상으로 남긴다.
- `_gj_backup` 복원은 동일 이름의 대상 `.mod`가 이미 있으면 건너뛰므로, 그런 PC 상태에서는 백업 폴더 복원이 누락될 수 있다. 실제 발생 여부는 PC 상태 보고서가 필요하다.
- 생성되는 모드 파일과 설치 코드는 변경하지 않았다. Windows에서 본문 1~7단계를 수행하고 실제 출력과 체크 결과로 갱신해야 한다.
