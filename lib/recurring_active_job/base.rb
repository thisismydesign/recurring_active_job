require "active_job"

module RecurringActiveJob
  class Base < ActiveJob::Base
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
      logger.debug("Performing #{job_info(job)}") if logger
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
        logger.info("#{recurring_active_job_info} was deactivated and is not requeued") if logger
        return
      end

      requeued_job = self.class.set(queue: job.queue_name, wait: @recurring_active_job.frequency_seconds.seconds).perform_later(job.arguments.first)
      logger.debug("Requeued #{job_info(requeued_job)}") if logger
    end

    def clean
      return if @recurring_active_job.active
      return unless @recurring_active_job.auto_delete
      logger.debug("Destroying #{recurring_active_job_info}") if logger
      @recurring_active_job.destroy!
    end

    def job_info(job)
      recurring_active_job_info + " job #{job.job_id} in queue #{job.queue_name}"
    end

    def recurring_active_job_info
      "RecurringActiveJob##{@recurring_active_job.id}"
    end

    def logger
      # TODO: make logger configurable
      Logger.new(STDOUT)
    end
  end
end
