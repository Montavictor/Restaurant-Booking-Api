class CreateBookingDates < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_dates do |t|
      t.date :date
      t.boolean :is_lunch_available
      t.boolean :is_dinner_available

      t.timestamps
    end
  end
end
