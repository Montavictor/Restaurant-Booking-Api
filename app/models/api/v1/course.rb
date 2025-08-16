class Api::V1::Course < ApplicationRecord
  has_many :meal_items, class_name: "Api::V1::MealItem", foreign_key: "api_v1_course_id", dependent: :destroy
  accepts_nested_attributes_for :meal_items, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
