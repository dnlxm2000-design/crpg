# Word 내보내기 가이드 (Word Export Guide)

**최종 업데이트:** 2026-04-18

---

## 목표
Markdown으로 작성한 계획/설계 문서를 Word(.docx)로 저장하기 위한 간단한 절차를 제공.

## 전제
Pandoc이 설치되어 있거나, 온라인 변환 도구를 사용 가능한 상태여야 함.

---

## 방법 A: Pandoc 사용
```bash
# 기본 변환
pandoc -s crpg_prototype/docs/plan.md -o crpg_prototype/docs/plan.docx

# 커스텀 템플릿 사용
pandoc -s plan.md -o plan.docx --reference-doc=templates/word_template.docx
```

## 방법 B: 온라인 도구 활용
- Markdown to DOCX 변환이 가능한 온라인 툴에 plan.md 업로드 후 DOCX로 다운로드

## 참고
- Word에서 직접 편집을 원하면 plan.md를 복사한 뒤 Word에 붙여넣고 저장해도 됨.
- 파일 포맷: plan.md의 구조를 유지하면 향후 Plan.docx에 반영 용이
