require "test_helper"
require "minitest/mock"

class OcrExtractionJobTest < ActiveJob::TestCase
  test "gracefully handles missing document" do
    assert_nothing_raised do
      OcrExtractionJob.perform_now(-1)
    end
  end

  test "stores extracted text when OCR succeeds" do
    document = Document.new
    document.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    document.save!

    fake_client = Class.new do
      def extract_text(_document)
        "Sample OCR text"
      end
    end.new

    Ocr::MistralClient.stub :new, fake_client do
      assert_enqueued_with(job: MetadataEnrichmentJob, args: [document.id]) do
        OcrExtractionJob.perform_now(document.id)
      end
    end

    document.reload
    assert_equal "Sample OCR text", document.ocr_text
    assert document.completed_status?
    assert_equal "processing", document.metadata_status
    assert_nil document.ocr_error_message
  end

  test "stores error when OCR fails" do
    document = Document.new
    document.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    document.save!

    failing_client = Class.new do
      def extract_text(_document)
        raise Ocr::MistralClient::Error, "HTTP 500"
      end
    end.new

    Ocr::MistralClient.stub :new, failing_client do
      assert_no_enqueued_jobs only: MetadataEnrichmentJob do
        OcrExtractionJob.perform_now(document.id)
      end
    end

    document.reload
    assert_equal "failed", document.ocr_status
    assert_equal "pending", document.metadata_status
    assert_equal "HTTP 500", document.ocr_error_message
    assert_nil document.ocr_text
  end
end
