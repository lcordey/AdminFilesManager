require "test_helper"
require "minitest/mock"

class MetadataEnrichmentJobTest < ActiveJob::TestCase
  test "updates document metadata when service succeeds" do
    document = Document.new
    document.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "tax_notice.pdf",
      content_type: "application/pdf"
    )
    document.ocr_text = "This is a tax notice for Loic Cordey from Tax Office."
    document.ocr_status = "completed"
    document.save!

    fake_client = Class.new do
      def extract_metadata(_text, filename:, document:)
        {
          title: "2024 Tax Notice",
          description: "Annual summary for Loïc Cordey",
          category: "Tax",
          people: ["Loïc Cordey"],
          organizations: ["Tax Office"]
        }
      end
    end.new

    Metadata::MistralClient.stub :new, fake_client do
      MetadataEnrichmentJob.perform_now(document.id)
    end

    document.reload
    assert_equal "2024 Tax Notice", document.title
    assert_equal "Annual summary for Loïc Cordey", document.description
    assert_equal "Tax", document.category
    assert_equal "Loïc Cordey", document.people
    assert_equal "Tax Office", document.organizations
    assert_equal "completed", document.metadata_status
    assert_nil document.metadata_error_message
  end

  test "handles missing document gracefully" do
    assert_nothing_raised { MetadataEnrichmentJob.perform_now(-1) }
  end

  test "stores error when metadata extraction fails" do
    document = Document.new
    document.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    document.ocr_text = "Sample text"
    document.ocr_status = "completed"
    document.save!

    failing_client = Class.new do
      def extract_metadata(*_args)
        raise Metadata::MistralClient::Error, "Timeout"
      end
    end.new

    Metadata::MistralClient.stub :new, failing_client do
      MetadataEnrichmentJob.perform_now(document.id)
    end

    document.reload
    assert_equal "failed", document.metadata_status
    assert_equal "Timeout", document.metadata_error_message
  end
end
