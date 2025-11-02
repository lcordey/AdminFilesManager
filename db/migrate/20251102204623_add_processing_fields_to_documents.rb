class AddProcessingFieldsToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :metadata_status, :string, null: false, default: "pending"
    add_column :documents, :metadata_error_message, :text
    add_column :documents, :ocr_error_message, :text
  end
end
