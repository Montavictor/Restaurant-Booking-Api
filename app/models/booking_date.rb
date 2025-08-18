
class BookingDate < ApplicationRecord
  has_many :reservation_infos, dependent: :destroy
  
  validates :date, presence: true, uniqueness: true
  
  def mark_slot_unavailable!(meal_period)
    case meal_period.downcase
    when 'lunch'
      update!(is_lunch_available: false)
    when 'dinner'
      update!(is_dinner_available: false)
    end
  end
  
  def release_slot!(meal_period)
    case meal_period.downcase
    when 'lunch'
      update!(is_lunch_available: true) unless other_confirmed_lunch_reservations?
    when 'dinner'
      update!(is_dinner_available: true) unless other_confirmed_dinner_reservations?
    end
  end
  
  private
  
  def other_confirmed_lunch_reservations?
    reservation_infos.where(meal_period: 'lunch', status: ['confirmed', 'pending']).exists?
  end
  
  def other_confirmed_dinner_reservations?
    reservation_infos.where(meal_period: 'dinner', status: ['confirmed', 'pending']).exists?
  end
end