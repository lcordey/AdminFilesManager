class ProcessingLog < ApplicationRecord
  STAGES = %w[ocr metadata].freeze
  DIRECTIONS = %w[request response].freeze
  STATUSES = %w[pending success error].freeze

  belongs_to :document

  validates :stage, inclusion: { in: STAGES }
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_stage, ->(stage) { where(stage: stage) }
end
