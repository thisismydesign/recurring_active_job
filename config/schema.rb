# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_27_123939) do

  create_table "recurring_active_jobs", force: :cascade do |t|
    t.string "job_id"
    t.string "provider_job_id"
    t.boolean "active", default: true, null: false
    t.integer "frequency_seconds", default: 600, null: false
    t.boolean "auto_delete", default: true, null: false
    t.string "last_error"
    t.text "last_error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_recurring_active_jobs_on_job_id", unique: true
    t.index ["provider_job_id"], name: "index_recurring_active_jobs_on_provider_job_id", unique: true
  end

end
