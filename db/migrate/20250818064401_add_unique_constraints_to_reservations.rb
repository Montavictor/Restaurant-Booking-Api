class AddUniqueConstraintsToReservations < ActiveRecord::Migration[7.2]
  def change
    add_index :reservation_infos, :stripe_id, unique: true
    add_index :reservation_infos, :cancellation_token, unique: true
  end
end
