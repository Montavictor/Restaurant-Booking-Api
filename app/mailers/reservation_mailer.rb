class ReservationMailer < ApplicationMailer
  default from: ENV.fetch('GMAIL_EMAIL')
  
  def confirmation_email(reservation)
    @reservation = reservation
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @reservation_date = reservation.booking_date&.date&.strftime("%B %d, %Y")
    @meal_period = reservation.meal_period
    @number_of_guest = reservation.number_of_guest
    @email = reservation.email
    @mobile_number = reservation.mobile_number
    @price = reservation.price
    @downpayment = reservation.downpayment
    @total = reservation.total
    @first_course = reservation.first_course
    @second_course = reservation.second_course
    @third_course = reservation.third_course
    @fourth_course = reservation.fourth_course
    @fifth_course = reservation.fifth_course
    @sixth_course = reservation.sixth_course
    @seventh_course = reservation.seventh_course
    @eighth_course = reservation.eighth_course
    @ninth_course = reservation.ninth_course
    @cancellation_token = reservation.cancellation_token

    mail(
      to: reservation.email,
      subject: "Reservation Confirmed - #{@reservation_date}",
      template_name: 'confirmation_email'
    )
  end
  
  def cancellation_email(reservation)
    @reservation = reservation
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @reservation_date = reservation.booking_date&.date&.strftime("%B %d, %Y")

    mail(
      to: reservation.email,
      subject: "Reservation Cancelled - #{@reservation_date}",
      template_name: 'cancellation_email'
    )
  end
  
  def reminder_email(reservation)
    @reservation = reservation
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @reservation_date = reservation.booking_date&.date&.strftime("%B %d, %Y")
    @meal_period = reservation.meal_period
    @number_of_guest = reservation.number_of_guest
    @email = reservation.email
    @mobile_number = reservation.mobile_number
    @downpayment = reservation.downpayment || 0
    @total = reservation.total

    mail(
      to: reservation.email,
      subject: "Reservation Reminder - #{reservation.meal_period.capitalize}",
      template_name: 'reminder_email'
    )
  end

  def admin_email(reservation)
    @reservation = reservation
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @reservation_date = reservation.booking_date&.date&.strftime("%B %d, %Y")
    @meal_period = reservation.meal_period
    @number_of_guest = reservation.number_of_guest
    @email = reservation.email
    @mobile_number = reservation.mobile_number
    @price = reservation.price
    @downpayment = reservation.downpayment || 0
    @total = reservation.total
    @first_course = reservation.first_course
    @second_course = reservation.second_course
    @third_course = reservation.third_course
    @fourth_course = reservation.fourth_course
    @fifth_course = reservation.fifth_course
    @sixth_course = reservation.sixth_course
    @seventh_course = reservation.seventh_course
    @eighth_course = reservation.eighth_course
    @ninth_course = reservation.ninth_course

    mail(
      to: ENV.fetch('GMAIL_EMAIL'),
      subject: "New Reservation - #{@reservation_date}",
      template_name: 'admin_email'
    )
  end
end
