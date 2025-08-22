FactoryBot.define do
  factory :booking_date do
    date { Date.tomorrow }
    is_lunch_available { true }
    is_dinner_available { true }
  end
end
