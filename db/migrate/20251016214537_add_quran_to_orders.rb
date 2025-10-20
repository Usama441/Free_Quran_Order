class AddQuranToOrders < ActiveRecord::Migration[7.2]
  def change
    # Add the polymorphic Quran association to orders
    add_column :orders, :quran_type, :string
    add_column :orders, :quran_id, :bigint

    # Optional: Add index for performance
    add_index :orders, [:quran_type, :quran_id]

    # Note: Since this is a polymorphic association that can theoretically
    # reference multiple models, we don't add an explicit foreign key constraint
  end
end
