class ReservationInfo < ApplicationRecord
  # Callbacks
  before_validation :set_defaults, :calculate_total
  before_create :generate_cancellation_token 
  # after_create :schedule_reminder_email
  
  # Associations
  belongs_to :booking_date, optional: true

  # Constants
  BASE_PRICE = 2_400
  MIN_DOWNPAYMENT = 10_000

  # Validations
  validate :booking_date_must_be_in_future
  validate :reservation_slot_must_be_available

  validates :first_name, :last_name, :email, :mobile_number,
            :reservation_date, :meal_period, :number_of_guest, presence: true

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 100 }
  validates :mobile_number, numericality: { only_integer: true }, length: { minimum: 12, maximum: 15 }
  validates :number_of_guest, numericality: { only_integer: true, greater_than_or_equal_to: 12, less_than_or_equal_to: 24 }
  validates :meal_period, inclusion: { in: %w[lunch dinner] }
  validates :downpayment, numericality: { only_integer: true }, allow_blank: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled] }, allow_nil: true
  validates :cancellation_token, uniqueness: true, allow_nil: true
  validates :customer_notes, length: { maximum: 500 }, allow_blank: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :first_course, :second_course, :third_course, :fourth_course,
            :fifth_course, :sixth_course, :seventh_course, :eighth_course,
            :ninth_course, presence: true, length: { maximum: 255 }

  private

  # Callbacks
  def set_defaults
    self.price ||= BASE_PRICE
  end  

  def generate_cancellation_token
    self.cancellation_token ||= SecureRandom.hex(10)
  end

  def reservation_slot_must_be_available
    return unless reservation_date.present? && meal_period.present?

    existing_reservations = ReservationInfo.joins(:booking_date)
                                           .where(booking_dates: { date: reservation_date })
                                           .where(meal_period: meal_period)
                                           .where.not(id: id)
    if existing_reservations.exists?
      errors.add(:base, "The selected meal period is already booked for this date.")
    end
  end

  def booking_date_must_be_in_future
    if reservation_date.present? && reservation_date.to_date < Date.today + 7.days
      errors.add(:reservation_date, "must be at least 1 week in advance")
    end
  end

  def calculate_total
    self.total = (price || BASE_PRICE) * (number_of_guest.to_i)
  end

  # def schedule_reminder_email
  #   return unless reservation_date.present?

  #   reminder_date = (reservation_date.to_date - 2.days).beginning_of_day + 9.hours
  #   ReservationReminderJob.set(wait_until: reminder_date).perform_later(self.id)
  # end

  # Class methods
  def self.calculate_amounts(guests, downpayment: nil)
    guests = guests.to_i
    price = BASE_PRICE
    downpayment = downpayment.to_i

    total = if downpayment.present? && downpayment >= MIN_DOWNPAYMENT && downpayment < price * guests
              downpayment * 100
            else
              price * guests * 100
            end

    { total: total }
  end
end
