require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = @original_queue_adapter
  end
  test "should get index" do
    get documents_url
    assert_response :success
  end

  test "should create document" do
    file = fixture_file_upload("sample.pdf", "application/pdf")

    assert_difference("Document.count", 1) do
      post documents_url, params: {
        document: {
          file: file
        }
      }
    end

    assert_redirected_to documents_url
  end

  test "should show document" do
    document = documents(:one)
    get document_url(document)
    assert_response :success
  end

  test "should reprocess document" do
    document = Document.new
    document.skip_ocr_job = true
    document.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    document.save!
    document.update!(
      ocr_status: "failed",
      metadata_status: "failed",
      ocr_error_message: "error",
      metadata_error_message: "error"
    )

    assert_enqueued_with(job: OcrExtractionJob, args: [document.id]) do
      post reprocess_document_url(document)
    end

    assert_redirected_to documents_url

    document.reload
    assert_equal "pending", document.ocr_status
    assert_equal "pending", document.metadata_status
    assert_nil document.ocr_error_message
    assert_nil document.metadata_error_message
  end
end
