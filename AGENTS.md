# Repository Guidelines

## Project Structure & Module Organization
- `app/` hosts Rails controllers, models, views, and components; prefer service objects under `app/services/` to orchestrate OCR calls and metadata enrichment.
- Background processing belongs in `app/jobs/`; queue names should reflect intent (`ocr_ingest`, `metadata_sync`) and enqueue from controllers or service objects.
- `db/` stores schema, seeds, and migrations; document default category seeds (tax, insurance, driving, kids) inline.
- Specs mirror the app layout inside `spec/`; place shared helpers in `spec/support/`. Uploaded blobs live in Active Storage’s `storage/`.

## Build, Test, and Development Commands
- `bin/setup` installs gems, prepares the database, and seeds baseline entities.
- `bin/rails server` starts the app on `http://localhost:3000`; use `bin/dev` if Hotwire+esbuild watchers are enabled.
- `bin/rails db:prepare` keeps dev and test schemas current before running workers or specs.
- `bundle exec rspec` runs the test suite; scope runs with `SPEC=spec/services/ocr_ingestion_spec.rb`.
- `bin/rails jobs:work` (or `bundle exec sidekiq`) processes queued OCR and metadata jobs locally.

## Coding Style & Naming Conventions
- Use two-space indentation and snake_case for methods/files; CamelCase for classes/modules.
- Run `bundle exec rubocop` before committing; keep `.rubocop.yml` authoritative for Ruby and Rails cops.
- Name jobs with `SomethingJob`, services with `SomethingService`, serializers/presenters with `SomethingSerializer`.
- Keep controllers thin—delegate OCR API calls to service objects and update records via POROs. Use Hotwire to broadcast OCR status changes when practical.

## Testing Guidelines
- Prefer RSpec: request specs (`spec/requests`), jobs (`spec/jobs`), services (`spec/services`), system specs for drag-and-drop uploads.
- Use FactoryBot factories (`spec/factories`) for `:admin_file`, `:entity`, `:user`.
- Stub the Mistral OCR API with WebMock/VCR; store cassettes under `spec/vcr`.
- Cover failure paths (OCR timeouts, invalid uploads) and ensure search scope specs assert filtering by tags, people, and categories.

## Commit & Pull Request Guidelines
- Write imperative commit messages: “Add OCR text persistence to FileRecord”.
- Keep commits focused—separate migrations, job wiring, and refactors where possible.
- Pull requests must include context, testing proof (`bundle exec rspec` output), and document new env vars (`MISTRAL_OCR_API_KEY`, `MISTRAL_OCR_ENDPOINT`).
- Attach UI screenshots or sample JSON when behavior changes; link to related issues or tickets for traceability.
