module DisruptionHelper

  def getURLToBusStop(busStop)
    if (busStop.instance_of?(BusStop))
      return 'http://countdown.tfl.gov.uk/#|searchTerm=' + busStop.code
    end
    return 'Undefined'
  end

  def getLinkToBusStop(busStop)
    if (busStop.instance_of?(BusStop))
      return '<a href="'+getURLToBusStop(busStop) + '" target="_blank">' + capitalizeAll(busStop.name) + '</a>'
    end
    return 'Undefined'
  end

  def getLinkToBusRoute(route, run)
    if (route != nil && run != nil)
      return '<a href="http://www.tfl.gov.uk/bus/route/' + route + '/?direction=' + run + '" target="_blank">' + route + '</a>'
    end
    return 'Undefined'
  end

  def secondsToMinutes(seconds)
    return (seconds / 60).round
  end

end