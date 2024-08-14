class AddCostCreditsToReplicatedCalls < ActiveRecord::Migration[7.0]
  def change
    add_column :replicated_calls, :cost_credits, :integer, null: false
  end
end
