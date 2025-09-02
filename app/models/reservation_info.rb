class ReservationInfo < ApplicationRecord
  # Callbacks
  before_validation :set_defaults, :calculate_total, :normalize_data
  before_create :generate_cancellation_token
  after_create :send_confirmation_email

  # Associations
  belongs_to :booking_date
  
  # Constants
  BASE_PRICE = 2_400
  MIN_DOWNPAYMENT = 10_000
  CANCEL_WINDOW_DAYS = 7
  STATUSES = %w[pending confirmed cancelled].freeze
  MEAL_PERIODS = %w[lunch dinner].freeze
  
  # Validations
  validates :first_name, :last_name, :email, :mobile_number,
            :reservation_date, :meal_period, :number_of_guest, presence: true
  
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, 
            length: { maximum: 100 }
  validates :mobile_number, format: { with: /\A09\d{9}\z/, message: "must start with 09 and be 11 digits long" }
  validates :number_of_guest, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 12, 
    less_than_or_equal_to: 24 
  }
  validates :meal_period, inclusion: { in: MEAL_PERIODS }
  validates :status, inclusion: { in: STATUSES }
  validates :cancellation_token, uniqueness: true, allow_nil: true
  validates :customer_notes, length: { maximum: 250 }, allow_blank: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :stripe_id, uniqueness: true, allow_nil: true
  
  # Course validations
  (1..9).each do |i|
    validates :"#{%w[first second third fourth fifth sixth seventh eighth ninth][i-1]}_course", 
              presence: true, length: { maximum: 100 }
  end
  
  # Custom validations
  validate :booking_date_must_be_in_future
  validate :cancellation_window_validation, on: :cancel
  validate :check_for_date_and_period, on: :create
  
  # Scopes
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :pending, -> { where(status: 'pending') }
  scope :for_date_and_period, ->(date, period) { 
    joins(:booking_date).where(booking_dates: { date: date }, meal_period: period) 
  }
  
  # Class methods
  def self.create_with_slot_reservation!(attributes)
    transaction do
      booking_date = BookingDate.lock.find_or_create_by!(date: attributes[:reservation_date])
      
      # Check slot availability with lock
      if slot_taken?(booking_date, attributes[:meal_period])
        raise ActiveRecord::RecordInvalid.new(new.tap { |r| 
          r.errors.add(:base, "The selected meal period is already booked for this date.") 
        })
      end
      
      reservation = create!(attributes.merge(booking_date: booking_date))
      booking_date.mark_slot_unavailable!(attributes[:meal_period])
      
      reservation
    end
  end
  
  def self.slot_taken?(booking_date, meal_period)
    exists?(booking_date: booking_date, meal_period: meal_period, status: ['confirmed', 'pending'])
  end
  
  def self.calculate_amounts(guests, downpayment: nil)
    guests = guests.to_i
    return { error: "Invalid number of guests" } if guests < 12 || guests > 24
    
    price = BASE_PRICE
    raw_downpayment = downpayment
    downpayment = downpayment.to_i
    
    total_amount = price * guests
    
    if downpayment.present? && downpayment >= MIN_DOWNPAYMENT && downpayment < total_amount
      amount_to_charge = downpayment
    else
      amount_to_charge = total_amount
    end
    
    {
      total: amount_to_charge * 100, # Stripe expects cents
      total_reservation_cost: total_amount, 
      is_partial_payment: raw_downpayment.present? && downpayment < total_amount
    }
  end
  
  # Instance methods
  def can_be_cancelled?
    return false if cancelled?
    reservation_date >= Date.current + CANCEL_WINDOW_DAYS.days
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def cancel_reservation!
    raise "Cannot cancel reservation" unless can_be_cancelled?
    
    transaction do
      lock!
      update!(status: 'cancelled')
      ReservationMailer.cancellation_email(self).deliver_now
      booking_date.release_slot!(meal_period)
    end
  end
  
  private
  
  def set_defaults
    self.price ||= BASE_PRICE
    self.status ||= 'pending'
  end
  
  def normalize_data
    self.email = email&.downcase&.strip
    self.first_name = first_name&.strip&.titleize
    self.last_name = last_name&.strip&.titleize
    self.mobile_number = mobile_number&.gsub(/\D/, '') # Remove non-digits
  end
  
  def generate_cancellation_token
    self.cancellation_token ||= SecureRandom.hex(16)
  end

  def send_confirmation_email
    ReservationMailer.confirmation_email(self).deliver_now
    ReservationMailer.admin_email(self).deliver_now
  end

  def check_for_date_and_period
    return unless reservation_date.present? && meal_period.present?

    if ReservationInfo.for_date_and_period(reservation_date, meal_period).exists?
      errors.add(:base, "The selected meal period is already booked for this date.")
    end
  end

  def booking_date_must_be_in_future
    return unless reservation_date.present?
    
    if reservation_date.to_date < Date.current + CANCEL_WINDOW_DAYS.days
      errors.add(:reservation_date, "must be at least #{CANCEL_WINDOW_DAYS} days in advance")
    end
  end
  
  def cancellation_window_validation
    return unless reservation_date.present?
    
    unless can_be_cancelled?
      errors.add(:base, "Reservation cannot be cancelled within #{CANCEL_WINDOW_DAYS} days of the reservation date")
    end
  end
  
  def calculate_total
    return unless number_of_guest.present? && price.present?
    self.total = price * number_of_guest.to_i
  end
end