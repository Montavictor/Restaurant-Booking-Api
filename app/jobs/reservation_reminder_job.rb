class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = ReservationInfo.find_by(id: reservation_id)
    ReservationMailer.reminder_email(reservation).deliver_now if reservation
  end
end
