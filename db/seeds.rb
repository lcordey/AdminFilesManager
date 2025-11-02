# frozen_string_literal: true

puts "Seeding documents..."

sample_pdf_path = Rails.root.join("db", "seeds", "files", "sample.pdf")
unless File.exist?(sample_pdf_path)
  warn "Sample PDF not found at #{sample_pdf_path}. Skipping document seeds."
  exit
end

docs = [
  {
    title: "Income Tax Notice",
    description: "Annual statement received from the tax office.",
    category: "Tax",
    people: "Loïc",
    organizations: "Tax Administration",
    ocr_text: "This is a sample OCR text snippet for the income tax notice.",
    ocr_status: "completed"
  },
  {
    title: "Car Insurance Policy",
    description: "Updated insurance coverage details for the family car.",
    category: "Insurance",
    people: "Loïc, Marie",
    organizations: "SafeDrive Insurance",
    ocr_text: "Sample policy summary captured by OCR.",
    ocr_status: "completed"
  }
]

docs.each do |attributes|
  document = Document.find_or_initialize_by(title: attributes[:title])
  document.skip_ocr_job = true
  document.assign_attributes(attributes)

  unless document.file.attached?
    document.file.attach(
      io: File.open(sample_pdf_path),
      filename: "#{attributes[:title].parameterize}.pdf",
      content_type: "application/pdf"
    )
  end

  document.save!
  puts "Seeded document: #{document.title}"
end

puts "Seeding complete."
