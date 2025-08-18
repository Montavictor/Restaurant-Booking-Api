class ReservationMailer < ApplicationMailer
  default from: ENV.fetch('RESERVATION_FROM_EMAIL', 'reservations@restaurant.com')
  
  def confirmation_email(reservation)
    @reservation = reservation
    @customer_name = "#{reservation.first_name} #{reservation.last_name}"
    
    mail(
      to: reservation.email,
      subject: "Reservation Confirmed - #{reservation.reservation_date}",
      template_name: 'confirmation'
    )
  end
  
  def cancellation_email(reservation)
    @reservation = reservation
    @customer_name = "#{reservation.first_name} #{reservation.last_name}"
    
    mail(
      to: reservation.email,
      subject: "Reservation Cancelled - #{reservation.reservation_date}",
      template_name: 'cancellation'
    )
  end
  
  def reminder_email(reservation)
    @reservation = reservation
    @customer_name = "#{reservation.first_name} #{reservation.last_name}"
    
    mail(
      to: reservation.email,
      subject: "Reservation Reminder - Tomorrow at #{reservation.meal_period.capitalize}",
      template_name: 'reminder'
    )
  end
end
