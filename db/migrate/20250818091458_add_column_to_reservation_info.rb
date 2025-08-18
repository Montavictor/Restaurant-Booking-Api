class AddColumnToReservationInfo < ActiveRecord::Migration[7.2]
  def change
    add_column :reservation_infos, :webhook_processed_at, :datetime
    add_index :reservation_infos, :webhook_processed_at
  end
end
