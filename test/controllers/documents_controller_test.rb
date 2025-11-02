require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
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
end
