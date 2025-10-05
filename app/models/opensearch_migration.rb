# frozen_string_literal: true

class OpensearchMigration < ApplicationRecord
  validates :version, presence: true, uniqueness: true
  validates :name, presence: true
  validates :applied_at, presence: true

  scope :ordered, -> { order(:version) }
end
