class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.text :description
      t.string :category
      t.text :people
      t.text :organizations
      t.text :ocr_text
      t.string :ocr_status, null: false, default: "pending"

      t.timestamps
    end

    add_index :documents, :title
    add_index :documents, :category
    add_index :documents, :ocr_status
  end
end
