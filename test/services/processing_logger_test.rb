require "test_helper"

class ProcessingLoggerTest < ActiveSupport::TestCase
  test "creates processing log entry" do
    document = build_document

    assert_difference("ProcessingLog.count", 1) do
      ProcessingLogger.log(
        document: document,
        stage: "ocr",
        direction: "request",
        status: "pending",
        payload: { info: "test" }.to_json
      )
    end
  end

  test "truncate payload to safe length" do
    document = build_document
    long_payload = "a" * 5000

    ProcessingLogger.log(
      document: document,
      stage: "ocr",
      direction: "response",
      status: "success",
      payload: long_payload
    )

    log = ProcessingLog.order(created_at: :desc).first
    assert log.payload.length <= 2000
  end

  private

  def build_document
    doc = Document.new
    doc.skip_ocr_job = true
    doc.file.attach(
      io: file_fixture("sample.pdf").open,
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    doc.save!
    doc
  end
end
