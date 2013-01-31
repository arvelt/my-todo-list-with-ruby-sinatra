Sequel.migration do
  up do
    create_table :todo do
      primary_key :id
      string :user_id
      string :status
      string :content
      timestamp :due_date
      timestamp :created_at
    end
  end

  down do
    drop_table :todo
  end
end
