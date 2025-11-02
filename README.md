# Admin Files Manager

Monolithic Ruby on Rails application that centralizes household administration documents. Upload files via the web UI, automatically extract searchable text with the Mistral OCR API, and enrich metadata with AI summaries.

## Getting Started

1. Run the bootstrap script the first time (installs gems, prepares DB, seeds demo docs, and ensures `.env` exists):
   ```bash
   ./scripts/setup
   ```
2. Start the app any time with:
   ```bash
   ./scripts/server
   ```
   Then open http://localhost:3000 in your browser.

## Configuration

Set the following environment variables before running OCR and metadata jobs:

- `MISTRAL_OCR_API_KEY` – API key for Mistral OCR requests.
- `MISTRAL_OCR_ENDPOINT` – Fully qualified endpoint URL (defaults to `https://api.mistral.ai/v1/ocr`).
- `MISTRAL_API_KEY` – Optional override key for metadata extraction (falls back to the OCR key when omitted).
- `MISTRAL_METADATA_ENDPOINT` / `MISTRAL_METADATA_MODEL` – Override chat endpoint/model used for metadata enrichment if needed.

Without these values the application still runs, uploads are stored locally, and OCR jobs will fail gracefully while leaving a clear audit trail in the logs.

Active Storage is configured for local disk storage in development and test. Uploaded files are saved under `storage/`.

## Features

- Single-field upload form; metadata (title, description, category, people, organizations) is auto-filled via the Mistral APIs.
- Metadata-aware document list with keyword search across title, category, people, and organizations.
- Background OCR extraction using Active Job; extracted text is stored on each document for future search capabilities.
- Detail page that surfaces metadata, download link, and OCR results.

## Testing

Run the Minitest suite with:
```bash
bundle exec rails test
```
Feature coverage includes model validations, job pipeline behavior, and controller endpoints. Tests stub the OCR client to keep suites deterministic.

## Next Steps

- Replace the placeholder Mistral OCR client payload with the exact API contract once finalized.
- Introduce authentication (e.g., devise) to restrict uploads to household members.
- Add richer search (full-text, tags) and filtering by people/entities.
- Wire up background processing with Sidekiq or Delayed Job for production workloads.
