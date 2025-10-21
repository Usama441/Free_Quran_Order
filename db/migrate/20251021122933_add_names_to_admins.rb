class AddNamesToAdmins < ActiveRecord::Migration[7.2]
  def change
    add_column :admins, :first_name, :string
    add_column :admins, :last_name, :string
  end
end
