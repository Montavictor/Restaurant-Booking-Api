class Course < ApplicationRecord
  has_many :meal_items, dependent: :destroy
  has_paper_trail on: [:update, :create, :destroy]

  validates :name, presence: true
  validates :position, presence: true
end