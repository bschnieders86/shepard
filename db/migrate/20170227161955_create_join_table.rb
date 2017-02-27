class CreateJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_join_table :services, :external_dependencies do |t|
      # t.index [:service_id, :external_dependency_id]
      # t.index [:external_dependency_id, :service_id]
    end
  end
end
