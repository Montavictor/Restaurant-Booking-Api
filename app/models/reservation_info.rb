class ReservationInfo < ApplicationRecord
  before_validation :set_defaults
  # associations
  belongs_to :booking_date

  # validations
  validates :first_name, :last_name, :email, :mobile_number, :reservation_date, :meal_period, :number_of_guest, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile_number, numericality: { only_integer: true }, length: { minimum: 12, maximum: 15 }

  validates :number_of_guest, numericality: { only_integer: true, greater_than_or_equal_to: 12, less_than_or_equal_to: 24 }
  validates :meal_period, inclusion: { in: %w[lunch dinner] }

  validates :status, inclusion: { in: %w[pending confirmed cancelled] }, allow_nil: true
  validates :cancellation_token, uniqueness: true, allow_nil: true

  validates :price, :downpayment, :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validates :customer_notes, length: { maximum: 500 }, allow_blank: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :email, length: { maximum: 100 }
  validates :first_course, :second_course, :third_course, :fourth_course, :fifth_course, :sixth_course, :seventh_course, :eighth_course, :ninth_course, length: { maximum:  40 }, allow_blank: true

  private

  def set_defaults
    self.price ||= 2400                 
  end  

  def self.calculate_amounts(guests, price: 2400)
    guests = guests.to_i
    price = price.to_i

    total = price * guests
    downpayment = total * 0.5 * 100 
    downpayment = downpayment.to_i
    {
      price: price,
      downpayment: downpayment,
      total: total * 100 
    }
  end
end
    