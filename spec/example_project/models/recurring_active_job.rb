class RecurringActiveJob < ApplicationRecord
  class << self
    attr_accessor :logger
  end
end
