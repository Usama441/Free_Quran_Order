class CreateExportHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :export_histories do |t|
      t.string :report_type
      t.date :start_date
      t.date :end_date
      t.string :format
      t.datetime :generated_at
      t.text :parameters

      t.timestamps
    end
  end
end
