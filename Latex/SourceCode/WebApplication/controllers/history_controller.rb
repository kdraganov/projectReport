class HistoryController < ApplicationController
  helper_method :sort_column, :sort_direction

  def filter
    checkParams
    @disruptions = getDisruptions(session[:fromFilter], session[:toFilter])
    render partial: 'list'
  end

  def index
    checkParams
    @disruptions = getDisruptions(session[:fromFilter], session[:toFilter])
  end

  private

  def getDisruptions(fromDate, toDate)
    if (toDate)
      begin
        to = Time.strptime(toDate, "%d/%m/%Y %H:%M:%S")
      rescue ArgumentError
        to = nil
      end
    end

    if (fromDate)
      begin
        from = Time.strptime(fromDate, "%d/%m/%Y %H:%M:%S")
      rescue ArgumentError
        from = nil
      end
    end

    whereClause = nil
    if (to != nil && from != nil)
      whereClause = "\"firstDetectedAt\" >= '"+ getFormatForDB(from)+ "' AND \"firstDetectedAt\" <= '"+getFormatForDB(to)+"'"
    elsif (to != nil)
      whereClause = "\"firstDetectedAt\" <= '"+ getFormatForDB(to)+"'"
    elsif (from != nil)
      whereClause = "\"firstDetectedAt\" >= '"+getFormatForDB(from)+"'"
    end

    order = {firstDetectedAt: :asc, delayInSeconds: :desc, routeTotalDelayInSeconds: :desc}
    if sort_column != false && sort_direction != false
      order = "\""+sort_column + "\" " + sort_direction
    end

    if (whereClause != nil)
      disruptions = Disruption.includes(:fromStop, :toStop).where(whereClause).order(order)
    else
      disruptions = Disruption.includes(:fromStop, :toStop).order(order)
    end

    return disruptions.paginate(:page => params[:page], :per_page => 20)
  end

  def getFormatForDB(time)
    return time.strftime("%Y-%m-%d %H:%M:%S")
  end


  def sort_column
    Disruption.column_names.include?(session[:sort]) ? session[:sort] : false
  end

  def sort_direction
    %w[asc desc].include?(session[:direction]) ? session[:direction] : false
  end

  def checkParams
    if params[:sort]
      session[:sort] = params[:sort]
    end
    if params[:direction]
      session[:direction] = params[:direction]
    end
    if params[:from]
      session[:fromFilter] = params[:from]
    end
    if params[:to]
      session[:toFilter] = params[:to]
    end
  end
end