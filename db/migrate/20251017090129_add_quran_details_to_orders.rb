class AddQuranDetailsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :quran_id, :bigint
    add_column :orders, :translation, :string
  end
end
