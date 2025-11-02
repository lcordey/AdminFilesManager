require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_queue_adapter
  end

  test "is valid with required attributes and attached file" do
    document = build_document
    assert document.valid?
  end

  test "requires a file attachment" do
    document = Document.new(title: "Missing file", category: "Tax")
    assert_not document.valid?
    assert_includes document.errors[:file], "must be attached"
  end

  test "enqueues ocr extraction job for supported file types" do
    document = build_document(content_type: "application/pdf")

    assert_enqueued_with(job: OcrExtractionJob) do
      assert document.save
    end
  end

  test "skips ocr job when flag is set" do
    document = build_document
    document.skip_ocr_job = true

    assert_no_enqueued_jobs only: OcrExtractionJob do
      assert document.save
    end
  end

  private

  def build_document(content_type: "application/pdf")
    Document.new(title: "Payslip", category: "Income").tap do |doc|
      doc.file.attach(
        io: file_fixture("sample.pdf").open,
        filename: "sample.pdf",
        content_type: content_type
      )
    end
  end
end
