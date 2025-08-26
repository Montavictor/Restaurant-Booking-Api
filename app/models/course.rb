class Course < ApplicationRecord
  has_many :meal_items, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true
end