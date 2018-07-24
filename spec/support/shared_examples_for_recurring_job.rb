require 'spec_helper'

# NOTE: `have_enqueued_job` matchers does not count the given block
# E.g. expect { described_class.perform_later }.not_to have_enqueued_job(described_class) => pass
RSpec.shared_examples "RecurringActiveJob" do
  let!(:recurring_active_job) { RecurringActiveJob::Model.create! }
  let(:recurring_job_params) { { recurring_active_job_id: recurring_active_job.id } }

  describe '#before_enqueue' do
    it 'sets `job_id` on recurring_active_job' do
      job = described_class.set(wait: 10.seconds).perform_later(recurring_job_params)
      expect(recurring_active_job.reload.job_id).to eq(job.job_id)
    end

    context "when missing recurring_active_job_id argument" do
      it "raises error" do
        expect {
          described_class.perform_later
        }.to raise_error(/Missing `recurring_active_job_id` argument/)
      end
    end
  end

  describe '#after_enqueue' do
    it 'sets `provider_job_id` on recurring_active_job' do
      allow_any_instance_of(described_class).to receive(:provider_job_id).and_return("provider_job_id")
      described_class.set(wait: 10.seconds).perform_later(recurring_job_params)
      expect(recurring_active_job.reload.provider_job_id).to eq("provider_job_id")
    end
  end

  describe '#after_perform' do
    context 'deactivated recurring_active_job' do
      let(:recurring_active_job) { RecurringActiveJob::Model.create!(active: false) }

      it 'does not requeue or change recurring_active_job' do
        expect {
          described_class.perform_later(recurring_job_params)
        }.not_to have_enqueued_job(described_class)
      end

      context "auto delete enabled" do
        before { recurring_active_job.update!(auto_delete: true) }

        it "destroys entity" do
          expect do
            described_class.perform_later(recurring_job_params)
          end.to change { RecurringActiveJob::Model.all.count }.by(-1)
        end
      end

      context "auto delete disabled" do
        before { recurring_active_job.update!(auto_delete: false) }

        it "does not destroy entity" do
          expect(recurring_active_job).not_to receive(:destroy!)
          
          expect do
            described_class.perform_later(recurring_job_params)
          end.not_to change { RecurringActiveJob::Model.all.count }
        end
      end
    end

    context 'active recurring_active_job' do
      let(:recurring_active_job) { RecurringActiveJob::Model.create!(active: true) }

      it 'requeues job with same arguments' do
        params = { recurring_active_job_id: recurring_active_job.id, abc: 123 }

        expect {
          described_class.perform_later(params)
        }.to have_enqueued_job(described_class).with(params)
      end

      it 'requeues job on same queue' do
        queue_name = "priority"

        expect {
          described_class.set(queue: queue_name).perform_later(recurring_job_params)
        }.to have_enqueued_job(described_class).on_queue(queue_name)
      end

      it "requeues job with given frequency" do
        Timecop.freeze(Time.current) do
          expect do
            described_class.set(wait: 10.minutes).perform_later(recurring_job_params)
          end.to have_enqueued_job(described_class).at(10.minutes.from_now)
        end
      end
    end
  end

  describe "logging" do
    it "doesn't log by default" do
      expect { described_class.perform_later(recurring_job_params) }.not_to output.to_stdout
    end

    context "when logger is set on class" do
      let (:temp_file) { Tempfile.new }

      before do
        logger = Logger.new(temp_file)
        logger.level = Logger::DEBUG
        RecurringActiveJob::Base.logger = logger
      end

      it "logs to provided logger" do
        expect {
          described_class.perform_later(recurring_job_params)
        }.to change { temp_file.rewind; temp_file.read }.from("")
      end
    end
  end

  describe "error handling" do
    it "bubbles up error" do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(StandardError, "error")
      
      expect { described_class.perform_later(recurring_job_params) }.to raise_error(StandardError, "error")
    end

    it "saves last_error upon exception" do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(StandardError, "error")
      
      expect do
        described_class.perform_later(recurring_job_params) rescue nil
      end.to change { recurring_active_job.reload.last_error }.from(nil)
    end

    it "saves last_error_details upon exception" do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(StandardError, "error")
      
      expect do
        described_class.perform_later(recurring_job_params) rescue nil
      end.to change { recurring_active_job.reload.last_error_details }.from(nil)
    end
  end
end
