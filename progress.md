# Progress Log

## Current State (2025-11-02)
- Rails monolith scaffolded with document uploads, OCR extraction, and metadata enrichment via Mistral APIs.
- Seeds provide two sample documents; scripts (`scripts/setup`, `scripts/server`) simplify bootstrap and run.
- Tests cover model defaults, controller upload flow, OCR job chaining, and metadata enrichment.

## Outstanding Work
1. **Verify Mistral API Contracts**
   - Confirm OCR payload/response schema matches production API.
   - Validate metadata chat prompt with real responses; adjust parsing and error handling accordingly.
2. **Background Job Infrastructure**
   - Choose adapter (Sidekiq/Delayed Job) for enqueueing OCR + metadata jobs outside web thread.
   - Add retry/backoff strategies and failure alerts/logging.
3. **Robust Error Surfacing**
   - Persist processing history (timestamps, attempt counts) for auditability.
   - Add user notifications (email/Slack) when processing fails repeatedly.
4. **Search Enhancements**
   - Index OCR text (e.g., PgSearch/SQLite FTS) and enable filtering by category/people/organizations.
5. **Authentication & Authorization**
   - Restrict access to household members (Devise or password-protected area).
6. **File Management UX**
   - Add previews/thumbnails, drag-and-drop upload widget, and progress indicators.
7. **Deployment Prep**
   - Containerize or create deployment scripts (Docker compose), configure environment variables, backups, and SSL for LAN access.
8. **Testing & Tooling**
   - Integrate HTTP stubbing (WebMock/VCR) for Mistral clients.
   - Add system tests covering full upload → OCR → metadata flow with mocked services.

## Notes for Next Session
- `.env` currently contains live API keys; avoid committing changes and rotate if exposed.
- Seeds set `skip_ocr_job` to prevent enqueuing background jobs when demo data loads.
- Remember to source `.env` before running scripts or server.
