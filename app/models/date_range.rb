# encoding: utf-8
class DateRange < Struct.new(:date_start, :date_end)
  def range
    date_start..date_end
  end

  def self.default
    last
  end

  def self.last(days = 30)
    d = Date.today
    new(d - days.days, d)
  end

  def self.range(s, e)
    s, e = (s.is_a?(String) ? Date.parse(s) : s), (e.is_a?(String) ? Date.parse(e) : e)
    new(s, e)
  end

  def self.parse(s, e)
    dr = new(Date.parse(s), Date.parse(e))
    raise 'Error'  unless dr.valid?
    dr
  rescue
    self.default
  end

  def valid?
    date_start.is_a?(Date) && date_end.is_a?(Date) && date_start <= date_end
  end
end

