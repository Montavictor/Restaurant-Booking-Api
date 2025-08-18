class ReservationMailer < ApplicationMailer
  default from: "no-reply@yourdomain.com"
  def confirmation_email(reservation)
    @reservation = reservation
    @booking_date = reservation.booking_date
    @reservation_date = @booking_date.date.strftime("%B %d, %Y")
    @meal_period = reservation.meal_period
    @number_of_guest = reservation.number_of_guest
    @customer_notes = reservation.customer_notes
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @mobile_number = reservation.mobile_number
    @email = reservation.email
    @price = reservation.price
    @downpayment = reservation.downpayment || 0
    @cancellation_token = reservation.cancellation_token
    @total = reservation.total || 0
    @courses = [
      @reservation.first_course,
      @reservation.second_course,
      @reservation.third_course,
      @reservation.fourth_course,
      @reservation.fifth_course,
      @reservation.sixth_course,
      @reservation.seventh_course,
      @reservation.eighth_course,
      @reservation.ninth_course
    ].compact # Ensure we only include non-nil courses
    mail(to: @reservation.email, subject: "Reservation Confirmation")
  end
  def cancellation_email(reservation)
    @reservation = reservation
    @cancellation_token = reservation.cancellation_token
    mail(to: @reservation.email, subject: "Your Reservation has been Cancelled")
  end
  def reminder_email(reservation)
    @reservation = reservation
    @booking_date = reservation.booking_date
    @reservation_date = @booking_date.date.strftime("%B %d, %Y")
    @meal_period = reservation.meal_period
    @number_of_guest = reservation.number_of_guest
    @customer_notes = reservation.customer_notes
    @first_name = reservation.first_name
    @last_name = reservation.last_name
    @mobile_number = reservation.mobile_number
    @email = reservation.email
    mail(to: @reservation.email, subject: "Reservation Reminder")
  end
end
