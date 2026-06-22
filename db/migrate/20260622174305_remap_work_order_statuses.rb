class RemapWorkOrderStatuses < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE work_orders SET status = CASE status
        WHEN 0 THEN 0
        WHEN 1 THEN 2
        WHEN 2 THEN 3
        WHEN 3 THEN 4
        WHEN 4 THEN 5
      END
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE work_orders SET status = CASE status
        WHEN 0 THEN 0
        WHEN 1 THEN 0
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 4
      END
    SQL
  end
end
