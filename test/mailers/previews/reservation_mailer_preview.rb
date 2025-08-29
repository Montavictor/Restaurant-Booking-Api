class ReservationMailerPreview < ActionMailer::Preview
  def admin_email
    reservation = ReservationInfo.first || ReservationInfo.new(
      first_name: "Juan",
      last_name: "Dela Cruz",
      email: "test@example.com",
      mobile_number: "09171234567",
      reservation_date: Date.tomorrow,
      meal_period: "dinner",
      number_of_guest: 12,
      price: 2400,
      downpayment: 10000,
      total: 28800,
      first_course: "Smoked salmon tartlet",
      second_course: "Roasted tomato basil soup",
      third_course: "Tuna tartare",
      fourth_course: "Caesar salad with parmesan crisps",
      fifth_course: "Seared scallops with lemon butter",
      sixth_course: "Wild mushroom risotto",
      seventh_course: "Beef tenderloin with red wine reduction",
      eighth_course: "Brie with fig jam",
      ninth_course: "Chocolate lava cake"
    )
    ReservationMailer.admin_email(reservation)
  end

  def cancellation_email
    reservation = ReservationInfo.first || ReservationInfo.new(
      first_name: "Juan",
      last_name: "Dela Cruz",
      email: "test@example.com",
      mobile_number: "09171234567",
      reservation_date: Date.tomorrow,
      meal_period: "dinner",
      cancellation_token: "sample-token"
    )
    ReservationMailer.cancellation_email(reservation)
  end

  def confirmation_email
    reservation = ReservationInfo.first || ReservationInfo.new(
      first_name: "Juan",
      last_name: "Dela Cruz",
      email: "test@example.com",
      mobile_number: "09171234567",
      reservation_date: Date.tomorrow,
      meal_period: "dinner",
      number_of_guest: 12,
      price: 2400,
      downpayment: 10000,
      total: 28800,
      first_course: "Smoked salmon tartlet",
      second_course: "Roasted tomato basil soup",
      third_course: "Tuna tartare",
      fourth_course: "Caesar salad with parmesan crisps",
      fifth_course: "Seared scallops with lemon butter",
      sixth_course: "Wild mushroom risotto",
      seventh_course: "Beef tenderloin with red wine reduction",
      eighth_course: "Brie with fig jam",
      ninth_course: "Chocolate lava cake",
      cancellation_token: "sample-token"
    )
    ReservationMailer.confirmation_email(reservation)
  end

  # ✅ Add preview for the Reminder email
  def reminder_email
    reservation = ReservationInfo.first || ReservationInfo.new(
      first_name: "Juan",
      last_name: "Dela Cruz",
      email: "test@example.com",
      mobile_number: "09171234567",
      reservation_date: Date.tomorrow,
      meal_period: "dinner",
      number_of_guest: 12,
      price: 2400,
      downpayment: 10000,
      total: 28800,
      first_course: "Smoked salmon tartlet",
      second_course: "Roasted tomato basil soup",
      third_course: "Tuna tartare",
      fourth_course: "Caesar salad with parmesan crisps",
      fifth_course: "Seared scallops with lemon butter",
      sixth_course: "Wild mushroom risotto",
      seventh_course: "Beef tenderloin with red wine reduction",
      eighth_course: "Brie with fig jam",
      ninth_course: "Chocolate lava cake"
    )
    ReservationMailer.reminder_email(reservation)
  end
end
