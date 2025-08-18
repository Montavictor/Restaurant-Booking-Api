class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = ReservationInfo.find_by(id: reservation_id)
    return unless reservation

    return if reservation.status == "cancelled"
    ReservationMailer.reminder_email(reservation).deliver_now
  end
end
