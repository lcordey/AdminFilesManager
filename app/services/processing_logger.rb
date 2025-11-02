# frozen_string_literal: true

class ProcessingLogger
  class << self
    def log(document:, stage:, direction:, status:, payload: nil, message: nil, response_code: nil)
      return unless document

      ProcessingLog.create!(
        document: document,
        stage: stage,
        direction: direction,
        status: status,
        payload: truncate(payload),
        message: message,
        response_code: response_code
      )
    rescue StandardError => e
      Rails.logger.error("[ProcessingLogger] failed to log event: #{e.message}")
    end

    private

    def truncate(content)
      return if content.blank?

      text = content.to_s
      return text if text.length <= 2000

      text[0...1997] + "..."
    end
  end
end
