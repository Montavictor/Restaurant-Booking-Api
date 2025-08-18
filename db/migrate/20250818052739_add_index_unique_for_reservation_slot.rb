class AddIndexUniqueForReservationSlot < ActiveRecord::Migration[7.2]
  def change
    add_index :reservation_infos, [:reservation_date, :meal_period],
      unique: true,
      name: 'idx_unique_reservation_slot'
  end
end
