# frozen_string_literal: true

class Todo < ApplicationRecord
  belongs_to :user

  validates :title, presence: true, length: {maximum: 160}
end
