class AddModelToReplicatedCalls < ActiveRecord::Migration[7.0]
  def change
    add_column :replicated_calls, :model, :string
  end
end
