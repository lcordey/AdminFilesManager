class CreateProcessingLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :processing_logs do |t|
      t.references :document, null: false, foreign_key: true
      t.string :stage, null: false
      t.string :direction, null: false
      t.string :status, null: false
      t.text :payload
      t.text :message
      t.integer :response_code

      t.timestamps
    end

    add_index :processing_logs, [:document_id, :stage]
    add_index :processing_logs, :created_at
  end
end
