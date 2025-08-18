class WebhookTracker
  EXPIRY_TIME = 24.hours.to_i
  
  def self.processed?(event_id)
    Rails.cache.exist?("webhook:processed:#{event_id}")
  end
  
  def self.mark_processed(event_id)
    Rails.cache.write("webhook:processed:#{event_id}", true, expires_in: EXPIRY_TIME)
  end
  
  def self.processing?(event_id)
    Rails.cache.exist?("webhook:processing:#{event_id}")
  end
  
  def self.mark_processing(event_id)
    Rails.cache.write("webhook:processing:#{event_id}", true, expires_in: 5.minutes)
  end
  
  def self.clear_processing(event_id)
    Rails.cache.delete("webhook:processing:#{event_id}")
  end
end