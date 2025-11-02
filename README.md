# Admin Files Manager

Monolithic Ruby on Rails application that centralizes household administration documents. Upload files via the web UI, tag them with useful metadata, and automatically extract searchable text by delegating to the Mistral OCR API.

## Getting Started

1. Ensure Ruby 3.0.2 and Bundler are available. Install project gems:
   ```bash
   export PATH="$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH"
   bundle install
   ```
2. Copy environment template and populate secrets:
   ```bash
   cp .env.example .env
   # edit .env to provide Mistral credentials
   ```
3. Create and migrate the SQLite database:
   ```bash
   bundle exec rails db:prepare
   ```
4. Launch the development server and open http://localhost:3000:
   ```bash
   bundle exec rails server
   ```

## Configuration

Set the following environment variables before running OCR jobs:

- `MISTRAL_OCR_API_KEY` – API key for authenticating requests.
- `MISTRAL_OCR_ENDPOINT` – Fully qualified endpoint URL (defaults to `https://api.mistral.ai/v1/ocr`).

Without these values the application still runs, uploads are stored locally, and OCR jobs will fail gracefully while leaving a clear audit trail in the logs.

Active Storage is configured for local disk storage in development and test. Uploaded files are saved under `storage/`.

## Features

- Upload form with fields for title, description, category, people, and organizations.
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
