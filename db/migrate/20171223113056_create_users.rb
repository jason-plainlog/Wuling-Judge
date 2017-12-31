class CreateUsers < ActiveRecord::Migration[5.1]
  def change
  	create_table :users do |t|
      t.integer :accepted
      t.integer :submitted
  		t.string :name
  		t.string :alias
  		t.string :password
  		t.string :created_at
  		t.text :info
  		t.text :status
  	end
  end
end
