class AddWebhookProcessedAtToReservationInfos < ActiveRecord::Migration[7.2]
  def change
    add_column :reservation_infos, :webhook_processed_at, :datetime
  end
end
