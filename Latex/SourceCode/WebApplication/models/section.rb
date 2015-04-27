class Section < ActiveRecord::Base
  self.table_name = "Sections"
  has_many :lostTimes, :class_name => "SectionsLostTime", :foreign_key => "sectionId", :primary_key => "id"
  has_one :latestLostTime, :class_name => "SectionsLostTime", :foreign_key => "serialId", :primary_key => "serialId"
  has_one :startStop, :class_name => "BusStop", :foreign_key => "lbslCode", :primary_key => "startStopLBSLCode"
  has_one :endStop, :class_name => "BusStop", :foreign_key => "lbslCode", :primary_key => "endStopLBSLCode"

  # has_one :latestLostTime, -> { where("\"SectionsLostTime\".timestamp = (SELECT \"Sections\".\"latestLostTimeUpdateTime\" FROM \"Sections\" WHERE \"SectionsLostTime\".\"sectionId\" = \"Sections\".id)") }, :class_name => "SectionsLostTime", :foreign_key => "sectionId", :primary_key => "id"

  def getLatestLostTimeMinutes
    return (self.latestLostTime.lostTimeInSeconds / 60).round
  end
end