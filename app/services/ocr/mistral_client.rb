# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "base64"

module Ocr
  class MistralClient
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ApiError < Error; end

    DEFAULT_ENDPOINT = "https://api.mistral.ai/v1/ocr".freeze

    def initialize(api_key: ENV["MISTRAL_OCR_API_KEY"], endpoint: ENV.fetch("MISTRAL_OCR_ENDPOINT", DEFAULT_ENDPOINT))
      raise ConfigurationError, "Missing MISTRAL_OCR_API_KEY" if api_key.to_s.strip.empty?

      @api_key = api_key
      @endpoint = URI.parse(endpoint)
    end

    def extract_text(document)
      document.file.blob.open do |file_io|
        payload = build_payload(file_io, document.file.filename.to_s, document.file.content_type)
        response = post_json(payload)
        parse_response(response)
      end
    end

    private

    attr_reader :api_key, :endpoint

    def build_payload(io, filename, content_type)
      {
        file_name: filename,
        content_type: content_type,
        content: Base64.strict_encode64(io.read)
      }
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
        raise ApiError, "OCR request failed with status #{response&.code}"
      end

      json = JSON.parse(response.body)
      json.fetch("text")
    rescue JSON::ParserError
      raise ApiError, "Unexpected response format from OCR service"
    end
  end
end
