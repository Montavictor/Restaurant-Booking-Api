class CreateReservationInfos < ActiveRecord::Migration[7.2]
  def change
    create_table :reservation_infos do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :mobile_number
      t.date :reservation_date
      t.string :meal_period
      t.integer :number_of_guest
      t.string :first_course
      t.string :second_course
      t.string :third_course
      t.string :fourth_course
      t.string :fifth_course
      t.string :sixth_course
      t.string :seventh_course
      t.string :eighth_course
      t.string :ninth_course
      t.string :customer_notes
      t.string :status
      t.string :cancellation_token
      t.string :stripe_id
      t.integer :price
      t.integer :downpayment
      t.integer :total
      t.references :booking_date, foreign_key: true

      t.timestamps
    end
  end
end
