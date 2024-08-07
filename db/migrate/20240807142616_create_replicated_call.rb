class CreateReplicatedCall < ActiveRecord::Migration[7.0]
  def change
    create_table :replicated_calls, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :predict_id, null: false
      t.integer :seed
      t.string :prompt, null: false
      t.integer :num_outputs
      t.string :aspect_ratio
      t.string :output_format
      t.integer :output_quality
      t.boolean :disable_safety_checker
      t.string :output
      t.jsonb :data
      t.timestamps
    end
  end
end
