class CreateAudits < ActiveRecord::Migration
  def self.up
    create_table :audits do |t|
      t.column :auditable_id,   :integer
      t.column :auditable_type, :string
      t.column :name,           :string
      t.column :status,         :integer, :null => false, :default => Audit::Statuses::SUCCESS
      t.column :parent_id,      :integer
      #t.column :errors_types,   :text
      t.column :description,    :text, :limit => 4.kilobytes
      t.column :comment,        :text
      t.timestamps
    end
  end

  def self.down
    drop_table :audits
  end
end
