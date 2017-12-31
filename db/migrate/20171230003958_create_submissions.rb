class CreateSubmissions < ActiveRecord::Migration[5.1]
  def change
  	create_table :submissions do |t|
  		t.integer :lang
  		t.integer :pid
  		t.integer :userid
  		t.integer :status
  		t.string :runtime
  		t.string :created_at
  	end
  end
end
