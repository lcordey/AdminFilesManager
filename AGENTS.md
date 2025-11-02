# Repository Guidelines

## Project Snapshot
- Purpose: Household admin document hub; users upload a file and the app auto-extracts OCR text plus metadata with Mistral APIs.
- Tech stack: Ruby 3.0.2, Rails 7.1, SQLite (dev/test), Active Storage (local disk), Active Job with inline queue (no Sidekiq yet).
- Scripts: `./scripts/setup` bootstraps gems + DB + seeds; `./scripts/server` runs `rails server`.

## Project Structure & Responsibilities
- `app/models/document.rb`: core record, attaches files, tracks `ocr_status` + `metadata_status`, stores error messages, and queues OCR/metadata jobs. Exposes `reprocess!` to reset and requeue.
- `app/jobs/ocr_extraction_job.rb` & `app/jobs/metadata_enrichment_job.rb`: background pipeline; update here when adding retries/backoff or additional status bookkeeping.
- `app/services/ocr/mistral_client.rb` & `app/services/metadata/mistral_client.rb`: HTTP clients for OCR and chat endpoints; keep request/response schemas in sync with upstream APIs.
- `app/controllers/documents_controller.rb` + `app/views/documents/`: upload form (file-only), listing, detail view.
- `db/seeds.rb`: seeds two sample docs using `db/seeds/files/sample.pdf` for demo state.
- Tests live in `test/` (Minitest). Use fixtures under `test/fixtures` and inline factories when needed.

## Runbook & Commands
- Install/prepare: `./scripts/setup` (idempotent; creates `.env` if missing).
- Start server: `./scripts/server` then visit `http://localhost:3000`.
- Run migrations manually: `bundle exec rails db:migrate`.
- Tests: `bundle exec rails test`.
- Background jobs currently run inline; start a dedicated worker later via `bin/rails jobs:work`.
- Retry failed processing from the browser via the "Retry processing" button (POST `/documents/:id/reprocess`), or manually call `Document#reprocess!` in the console.

## Configuration & Secrets
- `.env` (ignored by git) must define:
  - `MISTRAL_OCR_API_KEY`, `MISTRAL_OCR_ENDPOINT` (default `https://api.mistral.ai/v1/ocr`).
  - `MISTRAL_API_KEY` (fallbacks to OCR key), `MISTRAL_METADATA_ENDPOINT`, `MISTRAL_METADATA_MODEL` for chat completions.
- Update `.env.example` when configuration changes.

## Style & Contribution Guidelines
- Ruby style: 2-space indentation, `snake_case` methods, `CamelCase` classes. Keep controllers thin; push logic to services/jobs.
- Queue names should remain semantic (`default` for now); adjust when adding additional queues.
- When touching clients or jobs, add/adjust unit tests; stub external HTTP with custom doubles.
- Commit messages: imperative, scoped (e.g., "Handle OCR retries"). Describe env var changes in PR/commit body.
- Before pushing: run `bundle exec rails test`, ensure seeds succeed (`bundle exec rails db:seed`).

## Reference Links
- Rails Guides: https://guides.rubyonrails.org/
- Mistral OCR docs: https://docs.mistral.ai/api/#ocr (confirm exact endpoints before production use).
- Mistral chat completions: https://docs.mistral.ai/api/#tag/Chat-Completions.
