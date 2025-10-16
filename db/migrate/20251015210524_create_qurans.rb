class CreateQurans < ActiveRecord::Migration[7.2]
  def change
    create_table :qurans do |t|
      t.string :title
      t.string :writer
      t.string :translation
      t.integer :pages
      t.integer :stock
      t.text :description

      t.timestamps
    end
  end
end
