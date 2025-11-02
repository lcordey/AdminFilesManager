require "test_helper"
require "minitest/mock"

class OcrExtractionJobTest < ActiveJob::TestCase
  test "gracefully handles missing document" do
    assert_nothing_raised do
      OcrExtractionJob.perform_now(-1)
    end
  end

  test "stores extracted text when OCR succeeds" do
    document = Document.new(title: "Invoice", category: "Finance")
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
      OcrExtractionJob.perform_now(document.id)
    end

    document.reload
    assert_equal "Sample OCR text", document.ocr_text
    assert document.completed_status?
  end
end
