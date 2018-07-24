class CreateRecurringActiveJob < ActiveRecord::Migration[5.1]
  def change
    create_table :recurring_active_jobs do |t|
      t.string :job_id
      t.string :provider_job_id
      t.boolean :active, default: true, null: false
      t.integer :frequency_seconds, default: 600, null: false
      t.boolean :auto_delete, default: true, null: false
      t.string :last_error
      t.text :last_error_details

      t.timestamps
    end

    # Null values don't count towards uniqueness, see: https://github.com/rails/rails/issues/5853#issuecomment-5149938
    add_index :recurring_active_jobs, :job_id, unique: true
    add_index :recurring_active_jobs, :provider_job_id, unique: true
  end
end
