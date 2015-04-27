class DisruptionComment < ActiveRecord::Base
  self.table_name = "DisruptionComments"
  has_one :operator, :class_name => "Operator", :foreign_key => "id", :primary_key => "operatorId"
  belongs_to :disruption, :class_name => "Disruption", :foreign_key => "id", :primary_key => "disruptionId"

end