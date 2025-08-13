class BookingDate < ApplicationRecord
  has_many :reservation_infos, dependent: :destroy
  attribute :is_lunch_available, :boolean, default: true
  attribute :is_dinner_available, :boolean, default: true

  # validations
  validates :date, presence: true
  validates :is_lunch_available, inclusion: { in: [true, false] }
  validates :is_dinner_available, inclusion: { in: [true, false] }
end
