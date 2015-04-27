class SectionsLostTime < ActiveRecord::Base
  self.table_name = "SectionsLostTime"
  belongs_to :section, :class_name => "Sections", :foreign_key => "id", :primary_key => "sectionId"

end