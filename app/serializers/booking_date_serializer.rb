class BookingDateSerializer
  include JSONAPI::Serializer
  attributes :id, :date, :is_lunch_available, :is_dinner_available
end
