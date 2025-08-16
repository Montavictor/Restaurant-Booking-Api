class Api::V1::MealItem < ApplicationRecord
 belongs_to :courses, class_name: "Api::V1::Course", foreign_key: "api_v1_course_id", optional: true

  validates :name, presence: true
end
