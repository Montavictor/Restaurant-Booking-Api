class ReservationInfoSerializer
  include JSONAPI::Serializer
  attributes :id, :first_name, :last_name, :reservation_date, :meal_period, :number_of_guest

  attribute :booking_date do |reservation_info|
    bd = reservation_info.booking_date
    bd ? { id: bd.id, date: bd.date, is_lunch_available: bd.is_lunch_available, is_dinner_available: bd.is_dinner_available } : nil
  end
  belongs_to :booking_date
end
