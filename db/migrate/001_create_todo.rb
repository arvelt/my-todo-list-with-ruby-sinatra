Sequel.migration do
  up do
    create_table :todos do
      primary_key :id
      String :user_id
      String :status
      String :content
      DateTime :due_date
      DateTime :updated_at
      DateTime :created_at
    end
  end

  down do
    drop_table :todo
  end
end
