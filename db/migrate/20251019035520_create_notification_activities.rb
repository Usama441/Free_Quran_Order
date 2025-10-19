class CreateNotificationActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_activities do |t|
      t.string :event_type
      t.string :title
      t.string :message
      t.json :metadata
      t.string :sent_to
      t.string :status

      t.timestamps
    end
  end
end
