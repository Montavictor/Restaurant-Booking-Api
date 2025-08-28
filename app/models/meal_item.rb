class MealItem < ApplicationRecord
  belongs_to :course
  has_paper_trail
  
  validates :name, presence: true
  validates :description, presence: true
end