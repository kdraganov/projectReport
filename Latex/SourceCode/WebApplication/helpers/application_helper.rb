module ApplicationHelper
  require 'time'
  TIME_FORMAT = "%m/%d/%Y %H:%M:%S"

  def formatDatetimeString(timeString, format = TIME_FORMAT)
    return Time.strptime(timeString, format).strftime("%H:%M:%S")
  end

  def formatDatetimeStringWithDate(timeString, format = TIME_FORMAT)
    return Time.strptime(timeString, format).strftime("%H:%M:%S %m/%d/%Y")
  end

  def capitalizeAll(string)
    return string.split.map(&:capitalize).join(' ')
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : ""
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    return "<a class=\""+css_class.to_s+"\" onclick=\"sort('"+column+"','"+direction+"')\" "">"+title+"</a>"
    # link_to title, disruption_list_path({:sort => column, :direction => direction}), :remote => true, :id => "ajax_trigger", :class => css_class
  end

end
