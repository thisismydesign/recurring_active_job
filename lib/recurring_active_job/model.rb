require "active_record"

module RecurringActiveJob
  class Model < ActiveRecord::Base
    self.table_name = "recurring_active_jobs"

    class << self
      attr_accessor :logger
    end
  end  
end
