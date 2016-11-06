# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161106192336) do

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.text   "ingredients"
    t.float  "price"
  end

  create_table "orders", force: :cascade do |t|
    t.float    "total",        default: 0.0
    t.boolean  "order_placed", default: false
    t.integer  "user_id"
    t.datetime "order_time"
  end

  create_table "quantities", force: :cascade do |t|
    t.integer "item_id"
    t.integer "order_id"
    t.integer "amount"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
  end

end
