Sequel.migration do
  up do
    create_table :todos do
      primary_key :id
      string :user_id
      string :status
      string :content
      time :due_date
      time :updated_at
      time :created_at
    end
  end

  down do
    drop_table :todo
  end
end
