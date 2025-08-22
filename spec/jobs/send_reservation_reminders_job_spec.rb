require 'rails_helper'

RSpec.describe SendReservationRemindersJob, type: :job do
  let(:reservation_date) { Date.current + 10.days } 
  let(:reminder_date)    { reservation_date - 2.days } 
  
  before do
    booking_date = BookingDate.create!(date: Date.current + 2.days)
    
    @reservation = ReservationInfo.create!(
      booking_date: booking_date,
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@example.com',
      mobile_number: '12345678901',
      reservation_date: reminder_date,
      meal_period: 'lunch',
      number_of_guest: 12,
      status: 'confirmed',
      first_course: 'Test Course 1',
      second_course: 'Test Course 2',
      third_course: 'Test Course 3',
      fourth_course: 'Test Course 4',
      fifth_course: 'Test Course 5',
      sixth_course: 'Test Course 6',
      seventh_course: 'Test Course 7',
      eighth_course: 'Test Course 8',
      ninth_course: 'Test Course 9'
    )
  end
  
  it 'queues reminder emails for confirmed reservations' do
    expect {
      described_class.perform_now
    }.to have_enqueued_job(ReservationReminderJob).with(@reservation.id)
  end
  
  it 'marks reminders as sent' do
    described_class.perform_now
    @reservation.reload
    expect(@reservation.reminder_sent_at).to be_present
  end
  
  it 'does not send reminders twice' do
    @reservation.update!(reminder_sent_at: 1.hour.ago)
    
    expect {
      described_class.perform_now  
    }.not_to have_enqueued_job(ReservationReminderJob)
  end
end