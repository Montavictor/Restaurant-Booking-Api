class SendReservationRemindersJob < ApplicationJob
  queue_as :cron

  def perform
    Rails.logger.info "Starting reservation reminder job at #{Time.current}"
    
    reminder_date = Date.current + 2.days
    reservations = ReservationInfo.joins(:booking_date)
                                 .where(booking_dates: { date: reminder_date })
                                 .where(status: "confirmed")
                                 .where(reminder_sent_at: nil)
    Rails.logger.info "Found #{reservations.count} reservations for #{reminder_date}"
    
    sent_count = 0
    failed_count = 0

    return if reservations.empty?

    reservations.find_each do |reservation|
      begin
        ReservationReminderJob.perform_later(reservation.id)

        reservation.update_column(:reminder_sent_at, Time.current)
        sent_count += 1
        Rails.logger.info "Sent reminder for reservation #{reservation.id}"
      rescue => e
        Rails.logger.error "Failed to send reminder for reservation #{reservation.id}: #{e.message}"
        failed_count += 1
      end
    end
    Rails.logger.info "Reservations Reminders Job completed. Sent: #{sent_count}, Failed: #{failed_count}"
  end
end
