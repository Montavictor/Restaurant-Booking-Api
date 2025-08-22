class ReservationReminderJob < ApplicationJob
  queue_as :mailers
  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(reservation_id = nil)
    reservation = ReservationInfo.find_by(id: reservation_id)
    return unless reservation&.confirmed?
    
    if reservation.reminder_sent_at.present?
      Rails.logger.info "Reminder already sent for reservation #{reservation.id}"
      return
    end
    begin 
      ReservationMailer.reminder_email(reservation).deliver_now
      Rails.logger.info "Reminder email sent for reservation #{reservation.id}"
  rescue => e
    Rails.logger.error "Reminder email failed for reservation #{reservation_id}: #{e.message}"
      raise e
    end
  end
end