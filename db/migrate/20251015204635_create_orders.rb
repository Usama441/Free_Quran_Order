class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.string :full_name
      t.string :email
      t.string :phone
      t.text :address
      t.integer :quantity
      t.integer :status
      t.string :tracking_number
      t.boolean :email_verified
      t.boolean :phone_verified
      t.string :country_code
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :note

      t.timestamps
    end
  end
end
