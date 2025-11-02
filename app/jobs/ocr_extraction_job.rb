class OcrExtractionJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find_by(id: document_id)
    return unless document&.file&.attached?

    document.processing_status!

    begin
      text = Ocr::MistralClient.new.extract_text(document)
      document.update!(ocr_text: text, ocr_status: "completed")
      MetadataEnrichmentJob.perform_later(document.id)
    rescue Ocr::MistralClient::Error => e
      Rails.logger.error("[OcrExtractionJob] document_id=#{document_id} error=#{e.message}")
      document.update!(ocr_status: "failed", ocr_text: nil)
    end
  end
end
