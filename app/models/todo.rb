# frozen_string_literal: true

class Todo < ApplicationRecord
  belongs_to :user

  before_validation :set_position, on: :create

  validates :title, presence: true, length: {maximum: 160}
  validates :position, numericality: {only_integer: true, greater_than: 0}

  scope :ordered, -> { order(position: :asc, created_at: :asc, id: :asc) }

  private
    def set_position
      return if position.present? || user.blank?

      self.position = user.todos.maximum(:position).to_i + 1
    end
end
