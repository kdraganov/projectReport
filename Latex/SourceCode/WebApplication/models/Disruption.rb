class Disruption < ActiveRecord::Base
  self.table_name = "Disruptions"
  has_one :fromStop, :class_name => "BusStop", :foreign_key => "lbslCode", :primary_key => "fromStopLBSLCode"
  has_one :toStop, :class_name => "BusStop", :foreign_key => "lbslCode", :primary_key => "toStopLBSLCode"
  has_many :comments, :class_name => "DisruptionComment", :foreign_key => "disruptionId", :primary_key => "id"

  require 'time'
  TIME_FORMAT = "%m/%d/%Y %H:%M:%S"

  MEDIUM_THRESHOLD = 20
  SERIOUS_THRESHOLD = 40
  SEVERE_THRESHOLD = 60

  RED_COLOR = "#CC3333"
  YELLOW_COLOR = "#FFCC00"
  GREEN_COLOR = "#006633"
  ORANGE_COLOR = "#FF6600"

  TREND_SYMBOL_POSITIVE = "&#8593;"
  TREND_SYMBOL_NEGATIVE = "&#8595;"
  TREND_SYMBOL_NEUTRAL = "&#8597;"

  def getDetectedAt(date = false)
    if(date)
      format = "%H:%M:%S %m/%d/%Y"
    else
      format = "%H:%M:%S"
    end
    return self.firstDetectedAt.strftime(format)
  end

  def getClearedAt(date = false)
    if(date)
      format = "%H:%M:%S %m/%d/%Y"
    else
      format = "%H:%M:%S"
    end
    if (self.clearedAt != nil)
      return self.clearedAt.strftime(format)
    end
    return ""
  end

  def getRunString
    if (self.run == 1)
      return "Outbound"
    end
    return "Inbound"
  end

  def getDelay
    return secondsToMinutes(self.delayInSeconds)
  end

  def getTotalDelay
    return secondsToMinutes(self.routeTotalDelayInSeconds)
  end

  def totalDelayColor
    if (self.getTotalDelay > SEVERE_THRESHOLD)
      return "severe"
    end
    if (self.getTotalDelay > SERIOUS_THRESHOLD)
      return "serious"
    end
    return "medium"
  end

  def delayColor
    if (self.getDelay > SEVERE_THRESHOLD)
      return "severe"
    end
    if (self.getDelay > SERIOUS_THRESHOLD)
      return "serious"
    end
    return "medium"
  end

  def trendColor
    if (self.trend == 1)
      return "decrease"
    elsif (self.trend == 0)
      return "stable"
    else
      return "increase"
    end
  end

  def trendSymbol
    if (self.trend == 1)
      return TREND_SYMBOL_NEGATIVE
    elsif (self.trend == 0)
      return TREND_SYMBOL_NEUTRAL
    else
      return TREND_SYMBOL_POSITIVE
    end
  end

  def secondsToMinutes(seconds)
    return (seconds / 60).floor
  end
end
