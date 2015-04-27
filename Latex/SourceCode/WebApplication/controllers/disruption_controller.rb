class DisruptionController < ApplicationController
  helper_method :sort_column, :sort_direction
  before_filter :authenticateUser, :only => [:addComment, :hide]
  require 'time'
  $disruptionListLatUpdateTime = nil

  #Method responsible for querying the database for the details of a given disruption
  def details
    error = "<h1>No disruption specified</h1> <a class=\"close-reveal-modal\">&#215;</a>"
    id = nil
    begin
      id = Integer(params[:id])
    rescue ArgumentError
      render text: error and return
    end

    if (id == nil)
      render text: error and return
    end
    begin
      @disruption = Disruption.includes(:fromStop, :toStop).find(id)
    rescue ActiveRecord::RecordNotFound
      render text: error and return
    end
    if (@disruption == nil)
      render text: error and return
    end
    # @sections = Section.includes(:startStop, :endStop, :latestLostTime).where("route = ? AND run = ? ", @disruption.route, @disruption.run).order(sequence: :asc)
    @sections = Section.find_by_sql(['SELECT * FROM (
SELECT s.*, "SectionsLostTime".*,ROW_NUMBER() OVER(PARTITION BY s.id ORDER BY "SectionsLostTime".timestamp DESC) rn
FROM "SectionsLostTime" JOIN "Sections" s ON "SectionsLostTime"."sectionId" = s.id
WHERE s."route" = ? AND s.run = ? AND "SectionsLostTime".timestamp <= ? )
a WHERE rn = 1 ORDER BY a.sequence', @disruption.route, @disruption.run, @disruption.clearedAt == nil ? Time.now : @disruption.clearedAt])
    ActiveRecord::Associations::Preloader.new.preload(@sections, [:startStop, :endStop, :latestLostTime])

    startIndex = Section.where("route = ? AND run = ? AND \"startStopLBSLCode\" = ?", @disruption.route, @disruption.run, @disruption.fromStopLBSLCode)[0].sequence
    endIndex = Section.where("route = ? AND run = ? AND \"startStopLBSLCode\" = ?", @disruption.route, @disruption.run, @disruption.toStopLBSLCode)[0].sequence
    data = Array.new
    data.push(['Section', 'Section Lost Time', {type: 'string', role: 'annotation'},
               {type: 'string', role: 'tooltip', p: {html: true}}, {type: 'boolean', role: 'scope'},
               'Total Lost Time', {type: 'string', role: 'tooltip', p: {html: true}}, {type: 'boolean', role: 'scope'}])
    totalLostTime = 0
    sectionLostTime = 0
    @sections.each do |section|
      scope = false
      if (section.sequence == 1)
        label = capitalizeAll(section.startStop.name)
      elsif (section.sequence == @sections.length)
        label = capitalizeAll(section.endStop.name)
      else
        label = ''
      end
      lostTime = (section.latestLostTime.lostTimeInSeconds / 60).round
      lostTime = [lostTime, 0].max
      totalLostTime += lostTime

      if (section.sequence >= startIndex && section.sequence < endIndex)
        sectionLostTime += lostTime
        scope = true
      end

      tooltip = "From: <strong>"+getLinkToBusStop(section.startStop)+
          "</strong><br>To: <strong>" +getLinkToBusStop(section.endStop)+
          "</strong><br>Number of observation: <strong>" +
          section.latestLostTime.numberOfObservations.to_s+ "</strong>"

      totalTooltip = "Total minutes lost: <strong>"+totalLostTime.to_s+
          "</strong><br>From: <strong>" + getLinkToBusStop(section.startStop) +
          "</strong><br>To: <strong>" +getLinkToBusStop(section.endStop)

      data.push([label, lostTime, lostTime, tooltip, scope, totalLostTime, totalTooltip, true])
    end

    title = 'Route '+@disruption.route+' '+ @disruption.getRunString
    hAxisTitle = 'Total cumulative lost time observed along route '+totalLostTime.to_s+' minutes'
    @return = {:error => false, :update => true, :partial => render_to_string(:partial => "details"), :data => data, :title => title, :hAxisTitle => hAxisTitle}
    render :json => ActiveSupport::JSON.encode(@return)
  end

  # Lists all active disruptions in the network
  def list
    lastUpdateTime = getLatUpdateTime
    hidden = $disruptionListLatUpdateTime != nil && session[:disruptionListLatUpdateTime] <= $disruptionListLatUpdateTime
    dbUpdated = session[:fileVersion] == nil || session[:fileVersion] < lastUpdateTime
    if (hidden || dbUpdated || params[:sort])
      @lastUpdateTime = formatDatetimeString(lastUpdateTime)
      @disruptions = getDisruptions
      @return = {:error => false, :update => true, :partial => render_to_string(:partial => "list"), :timeout => TIMEOUT} #, :lastUpdateTime => formatDatetimeString(lastUpdateTime)
    else
      @return = {:error => false, :update => false, :timeout => TIMEOUT} #, :lastUpdateTime => formatDatetimeString(lastUpdateTime)
    end
    render :json => ActiveSupport::JSON.encode(@return)
  end

  def index
    @lastUpdateTime = formatDatetimeString(getLatUpdateTime)
    @timeout = TIMEOUT
    @disruptions = getDisruptions
  end

  def hide
    id = nil
    begin
      id = Integer(params[:id])
    rescue ArgumentError
      render :json => ActiveSupport::JSON.encode({:error => true, :errorInfo => "Invalid disruption selected!"}) and return
    end
    begin
      disruption = Disruption.find(id)
    rescue ActiveRecord::RecordNotFound
      render :json => ActiveSupport::JSON.encode({:error => true, :errorInfo => "Invalid disruption selected!"}) and return
    end
    if (disruption == nil)
      render :json => ActiveSupport::JSON.encode({:error => true, :errorInfo => "Invalid disruption selected!"}) and return
    end
    disruption.hide = !disruption.hide
    disruption.save
    $disruptionListLatUpdateTime = DateTime.now
    list and return
  end

  def addComment
    id = nil
    commentText = nil
    begin
      id = Integer(params[:id])
      commentText = params[:comment]
    rescue ArgumentError
      render :json => ActiveSupport::JSON.encode({:error => true, :message => "Incorrect parameters."}) and return
    end
    if (commentText == nil)
      render :json => ActiveSupport::JSON.encode({:error => true, :message => "Comment is empty."}) and return
    end
    begin
      disruption = Disruption.find(id)
    rescue ActiveRecord::RecordNotFound
      render :json => ActiveSupport::JSON.encode({:error => true, :message => "Invalid disruption."}) and return
    end
    if (disruption == nil)
      render :json => ActiveSupport::JSON.encode({:error => true, :message => "Invalid disruption."}) and return
    end
    comment = DisruptionComment.new
    comment.disruptionId = disruption.id
    comment.comment = commentText
    comment.operatorId = session[:operatorId]
    comment.save
    @disruption = Disruption.includes(:comments).find(id)
    @return = {:error => false, :partial => render_to_string(:partial => "comments")}
    render :json => ActiveSupport::JSON.encode(@return)
  end

  def comments
    error = "<h1>No disruption specified</h1> <a class=\"close-reveal-modal\">&#215;</a>"
    id = nil
    begin
      id = Integer(params[:id])
    rescue ArgumentError
      render text: error and return
    end
    if (id == nil)
      render text: error and return
    end
    begin
      @disruption = Disruption.includes(:comments).find(id)
    rescue ActiveRecord::RecordNotFound
      render text: error and return
    end
    if (@disruption == nil)
      render text: error and return
    end
    render partial: "comments"
  end

  private
  #Time between each Ajax update call for the disruption list
  TIMEOUT = 1000
  TIME_FORMAT = "%Y/%m/%d %H:%M:%S"

  def getLatUpdateTime
    return Time.strptime(EngineConfiguration.find("latestFeedTime").value, TIME_FORMAT)
  end

  def getDisruptions
    session[:disruptionListLatUpdateTime] = DateTime.now.in_time_zone('London')
    session[:fileVersion] = getLatUpdateTime
    whereClause = "\"clearedAt\" IS NULL"
    order = {hide: :asc, delayInSeconds: :desc, routeTotalDelayInSeconds: :desc, firstDetectedAt: :desc}
    if session[:operatorId] == nil
      whereClause += " AND NOT \"hide\""
      order.drop(1)
    end
    if sort_column != false && sort_direction != false
      order = "\""+sort_column + "\" " + sort_direction
    end
    disruptions = Disruption.includes(:fromStop, :toStop).where(whereClause).order(order)
    return disruptions.paginate(:page => params[:page], :per_page => 20)
  end

  def formatDatetimeString(timeString)
    return timeString.strftime("%H:%M:%S %d/%m/%Y")
  end

  def capitalizeAll(string)
    return string.split.map(&:capitalize).join(' ')
  end

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

  def sort_column
    if params[:sort]
      session[:sort] = params[:sort]
    end
    Disruption.column_names.include?(session[:sort]) ? session[:sort] : false
  end

  def sort_direction
    if params[:direction]
      session[:direction] = params[:direction]
    end
    %w[asc desc].include?(session[:direction]) ? session[:direction] : false
  end

end
