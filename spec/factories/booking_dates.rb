FactoryBot.define do
  factory :booking_date do
    sequence(:date) { |n| Date.today + 7.days + n }
    is_lunch_available { true }
    is_dinner_available { true }
  end
end
