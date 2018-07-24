require "active_job"

module RecurringActiveJob
  class Base < ActiveJob::Base
    class << self
      attr_accessor :logger
    end

    retry_on(StandardError, attempts: 0) do |job, e|
      recurring_active_job = RecurringActiveJob::Model.find(job.arguments.first&.dig(:recurring_active_job_id))
      if ActiveJob.gem_version < Gem::Version.new("5.2.0")
        recurring_active_job.update!(last_error: e, last_error_details: e)
      else
        recurring_active_job.update!(last_error: "#{e.class}: #{e.message}", last_error_details: ruby_style_error(e))
      end
      raise e
    end

    before_enqueue do |job|
      raise "Missing `recurring_active_job_id` argument" unless job.arguments.first&.dig(:recurring_active_job_id)
      load_recurring_active_job(job.arguments.first&.dig(:recurring_active_job_id))
      @recurring_active_job.job_id = job.job_id
      @recurring_active_job.save!
    end

    after_enqueue do |job|
      # provider_job_id is first available after enqueue
      @recurring_active_job.provider_job_id = job.provider_job_id
      @recurring_active_job.save!
    end

    before_perform do |job|
      load_recurring_active_job(job.arguments.first[:recurring_active_job_id])
      logger&.debug("Performing #{job_info(job)}")
    end
      
    after_perform do |job|
      requeue(job)
      clean
    end

    def perform(*args); end

    private

    def load_recurring_active_job(id)
      @recurring_active_job ||= RecurringActiveJob::Model.find(id)
    end

    def requeue(job)
      unless @recurring_active_job.active
        logger&.info("#{recurring_active_job_info} was deactivated and is not requeued")
        return
      end

      requeued_job = self.class.set(queue: job.queue_name, wait: @recurring_active_job.frequency_seconds.seconds).perform_later(job.arguments.first)
      logger&.debug("Requeued #{job_info(requeued_job)}")
    end

    def clean
      return if @recurring_active_job.active
      return unless @recurring_active_job.auto_delete
      logger&.debug("Destroying #{recurring_active_job_info}")
      @recurring_active_job.destroy!
    end

    def job_info(job)
      recurring_active_job_info + " job #{job.job_id} in queue #{job.queue_name}"
    end

    def recurring_active_job_info
      "RecurringActiveJob##{@recurring_active_job.id}"
    end

    def logger
      self.class.logger
    end

    def self.ruby_style_error(e)
      e.backtrace.join("\n\t")
      .sub("\n\t", ": #{e}#{e.class ? " (#{e.class})" : ''}\n\t")
    end
  end
end
