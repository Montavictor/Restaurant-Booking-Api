FactoryBot.define do
  factory :reservation_info do
    first_name { "John" }
    last_name { "Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    mobile_number { "12345678190" }
    reservation_date { Date.tomorrow + 7.days }
    meal_period { "dinner" }
    number_of_guest { 12 }
    customer_notes { "Anniversary dinner" }
    first_course { "Salad" }
    second_course { "Soup" }
    third_course { "Soup" }
    fourth_course { "Soup" }
    fifth_course { "Soup" }
    sixth_course { "Soup" }
    seventh_course { "Soup" }
    eighth_course { "Soup" }
    ninth_course { "test" }
    status { "confirmed" }
    cancellation_token { SecureRandom.hex(16) }
    association :booking_date

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_payment do
      stripe_id { "pi_#{SecureRandom.hex(12)}" }
    end

    trait :lunch do
      meal_period { "lunch" }
    end

    trait :dinner do
      meal_period { "dinner" }
    end
  end
end