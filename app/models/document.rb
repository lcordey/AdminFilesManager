class Document < ApplicationRecord
  attr_accessor :skip_ocr_job

  OCR_SUPPORTED_TYPES = %w[application/pdf image/png image/jpeg image/tiff].freeze

  has_one_attached :file

  enum ocr_status: {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, _suffix: :status

  validates :title, presence: true
  validates :category, presence: true
  validate :file_must_be_attached

  after_initialize :set_defaults
  after_commit :enqueue_ocr_extraction, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :search, lambda { |term|
    sanitized = "%#{term.downcase.strip}%"
    where(
      "lower(title) LIKE ? OR lower(category) LIKE ? OR lower(people) LIKE ? OR lower(organizations) LIKE ?",
      sanitized, sanitized, sanitized, sanitized
    )
  }

  def people_list
    split_list(people)
  end

  def organizations_list
    split_list(organizations)
  end

  def supports_ocr?
    return false unless file.attached?

    OCR_SUPPORTED_TYPES.include?(file.content_type)
  end

  private

  def set_defaults
    self.ocr_status ||= "pending"
  end

  def enqueue_ocr_extraction
    return if skip_ocr_job
    return unless supports_ocr?

    OcrExtractionJob.perform_later(id)
  end

  def split_list(value)
    Array(value.to_s.split(",")).map(&:strip).reject(&:blank?)
  end

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
