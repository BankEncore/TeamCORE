# frozen_string_literal: true

class CreateUsersAndUserAgencies < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :user_agencies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :agency, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_agencies, %i[user_id agency_id], unique: true
  end
end
