# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "active_support/core_ext/hash/indifferent_access"

module Metadata
  class MistralClient
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ApiError < Error; end

    DEFAULT_ENDPOINT = "https://api.mistral.ai/v1/chat/completions"
    DEFAULT_MODEL = "mistral-small-latest"

    def initialize(
      api_key: ENV["MISTRAL_API_KEY"] || ENV["MISTRAL_OCR_API_KEY"],
      endpoint: ENV.fetch("MISTRAL_METADATA_ENDPOINT", DEFAULT_ENDPOINT),
      model: ENV.fetch("MISTRAL_METADATA_MODEL", DEFAULT_MODEL)
    )
      raise ConfigurationError, "Missing Mistral API key" if api_key.to_s.strip.empty?

      @api_key = api_key
      @endpoint = URI.parse(endpoint)
      @model = model
    end

    def extract_metadata(ocr_text, filename: nil, document: nil)
      payload = build_payload(ocr_text, filename)
      log_request(document, payload) if document

      response = post_json(payload)
      log_response(document, response) if document

      parse_response(response)
    rescue ApiError => e
      log_error(document, e) if document
      raise
    end

    private

    attr_reader :api_key, :endpoint, :model

    def build_payload(ocr_text, filename)
      {
        model: model,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: "You extract structured metadata from household administrative documents."
          },
          {
            role: "user",
            content: user_prompt(ocr_text, filename)
          }
        ]
      }
    end

    def user_prompt(ocr_text, filename)
      <<~PROMPT
        Analyze the following document text and return JSON with this structure:
        {
          "title": <string>,
          "description": <string>,
          "category": <string>,
          "people": [<string>],
          "organizations": [<string>]
        }

        If a field cannot be determined, return null for title/description/category and an empty array for lists.
        Focus on household administration domains such as tax, insurance, driving, education, healthcare, housing, and utilities.
        Document filename: #{filename if filename.present?}

        Document text:
        #{ocr_text}
      PROMPT
    end

    def post_json(payload)
      http = Net::HTTP.new(endpoint.host, endpoint.port)
      http.use_ssl = endpoint.scheme == "https"

      request = Net::HTTP::Post.new(endpoint.request_uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      http.request(request)
    rescue SocketError, Errno::ECONNREFUSED => e
      raise ApiError, e.message
    end

    def parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Metadata request failed with status #{response&.code}"
      end

      json = JSON.parse(response.body)
      choice = json.fetch("choices").first
      content = choice&.dig("message", "content")
      raise ApiError, "Missing metadata content" if content.blank?

      data = JSON.parse(content)
      {
        title: data["title"],
        description: data["description"],
        category: data["category"],
        people: data["people"],
        organizations: data["organizations"]
      }.with_indifferent_access.symbolize_keys
    rescue JSON::ParserError
      raise ApiError, "Unexpected response format from metadata service"
    end

    def log_request(document, payload)
      summary = payload.dup
      summary[:messages] = summary[:messages].map do |message|
        content = message[:content].to_s
        message.merge(content: truncate(content))
      end

      ProcessingLogger.log(
        document: document,
        stage: "metadata",
        direction: "request",
        status: "pending",
        payload: summary.to_json
      )
    end

    def log_response(document, response)
      ProcessingLogger.log(
        document: document,
        stage: "metadata",
        direction: "response",
        status: response.is_a?(Net::HTTPSuccess) ? "success" : "error",
        payload: safe_response_body(response),
        response_code: response&.code&.to_i
      )
    end

    def log_error(document, error)
      ProcessingLogger.log(
        document: document,
        stage: "metadata",
        direction: "response",
        status: "error",
        message: error.message
      )
    end

    def truncate(content)
      text = content.to_s
      return text if text.length <= 2000

      text[0...1997] + "..."
    end

    def safe_response_body(response)
      return unless response

      body = response.body.to_s
      body.length > 2000 ? body[0...1997] + "..." : body
    end
  end
end
