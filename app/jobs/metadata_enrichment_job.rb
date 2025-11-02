class MetadataEnrichmentJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find_by(id: document_id)
    return unless document&.ocr_text.present?

    document.update!(metadata_status: "processing", metadata_error_message: nil)

    client = Metadata::MistralClient.new
    metadata = client.extract_metadata(
      document.ocr_text,
      filename: document.file&.filename&.to_s
    )

    document.update!(
      title: metadata[:title].presence || document.title,
      description: metadata[:description].presence || document.description,
      category: metadata[:category].presence || document.category,
      people: serialize_list(metadata[:people]) || document.people,
      organizations: serialize_list(metadata[:organizations]) || document.organizations,
      metadata_status: "completed"
    )
  rescue Metadata::MistralClient::Error => e
    Rails.logger.error("[MetadataEnrichmentJob] document_id=#{document_id} error=#{e.message}")
    document&.update!(metadata_status: "failed", metadata_error_message: e.message)
  end

  private

  def serialize_list(values)
    return if values.blank?

    Array(values).map(&:to_s).map(&:strip).reject(&:blank?).join(", ")
  end
end
