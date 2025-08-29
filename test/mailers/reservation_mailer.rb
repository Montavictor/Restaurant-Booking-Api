class ReservationMailer < ApplicationMailer
  default from: "stocksreplysample@gmail.com"

  def admin_email(reservation)
    @reservation = reservation
    mail(to: "admin@example.com", subject: "New Reservation Received")
  end

  def cancellation_email(reservation)
    @reservation = reservation
    mail(to: @reservation.email, subject: "Reservation Cancelled")
  end

  def confirmation_email(reservation)
    @reservation = reservation
    mail(to: @reservation.email, subject: "Reservation Confirmation")
  end

  def reminder_email(reservation)
    @reservation = reservation
    mail(to: @reservation.email, subject: "Reservation Reminder")
  end
end
