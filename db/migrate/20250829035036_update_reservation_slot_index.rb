class UpdateReservationSlotIndex < ActiveRecord::Migration[7.2]
  def change
    # Remove the old unique index
    remove_index :reservation_infos, name: "idx_unique_reservation_slot"

    # Add a new unique index that only considers confirmed reservations
    add_index :reservation_infos, [:reservation_date, :meal_period], 
              unique: true, 
              name: "idx_unique_reservation_slot", 
              where: "status = 'confirmed'"
  end
end
