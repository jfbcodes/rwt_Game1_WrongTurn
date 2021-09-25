class CreateParticipants < ActiveRecord::Migration[6.1]
  def change
    create_table :participants, id: :uuid do |t|
      t.string :username
      t.string :email
      t.string :phone
      t.string :referral_id
      t.string :password # probably not a good idea to store the password in plain text in a real app

      t.timestamps
    end
  end
end
