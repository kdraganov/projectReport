class BusStop < ActiveRecord::Base
  self.table_name = "BusStops"
  belongs_to :fromStop, :class_name => "Disruption", :foreign_key => "fromStopLBSLCode", :primary_key => "lbslCode"
  belongs_to :toStop, :class_name => "Disruption", :foreign_key => "toStopLBSLCode", :primary_key => "lbslCode"
  belongs_to :startStop, :class_name => "Section", :foreign_key => "startStopLBSLCode", :primary_key => "lbslCode"
  belongs_to :endStop, :class_name => "Section", :foreign_key => "endStopLBSLCode", :primary_key => "lbslCode"
end
