Sequel.migration do
  up do
    create_table(:events) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :value, "blob", :null=>false
      column :timestamp, "datetime", :null=>false
      index [:uuid], :unique=>true, :name=>:uuid
    end
  end

  down do
    drop_table(:events)
  end
end
