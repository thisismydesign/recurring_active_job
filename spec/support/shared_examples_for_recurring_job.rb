require 'spec_helper'

RSpec.shared_examples "RecurringActiveJob" do
  let!(:recurring_active_job) { RecurringActiveJob::Model.create! }
  let(:recurring_job_params) { { recurring_active_job_id: recurring_active_job.id } }
  let(:conigured_job_mock) { double("ActiveJob::ConfiguredJob") }

  describe '#before_enqueue' do
    it 'sets `job_id` on recurring_active_job' do
      job = described_class.set(wait: 10.seconds).perform_later(recurring_job_params)
      expect(recurring_active_job.reload.job_id).to eq(job.job_id)
    end
  end

  describe '#after_enqueue' do
    it 'sets `provider_job_id` on recurring_active_job' do
      allow_any_instance_of(described_class).to receive(:provider_job_id).and_return("provider_job_id")
      described_class.set(wait: 10.seconds).perform_now(recurring_job_params)
      expect(recurring_active_job.reload.provider_job_id).to eq("provider_job_id")
    end
  end

  # TODO: Use rspec-rails matchers (e.g. `have_enqueued_job`) instead of mocks
  describe '#after_perform' do
    context 'deactivated recurring_active_job' do
      let(:recurring_active_job) { RecurringActiveJob::Model.create!(active: false) }

      it 'does not requeue or change recurring_active_job' do
        allow(described_class).to receive_message_chain(:set).and_return(conigured_job_mock)
        expect(conigured_job_mock).not_to receive(:perform_later)

        described_class.perform_now(recurring_job_params)
      end

      context "auto delete enabled" do
        before { recurring_active_job.update!(auto_delete: true) }

        it "destroys entity" do
          expect do
            described_class.perform_now(recurring_job_params)
          end.to change { RecurringActiveJob::Model.all.count }.by(-1)
        end
      end

      context "auto delete disabled" do
        before { recurring_active_job.update!(auto_delete: false) }

        it "does not destroy entity" do
          expect(recurring_active_job).not_to receive(:destroy!)
          
          expect do
            described_class.perform_now(recurring_job_params)
          end.not_to change { RecurringActiveJob::Model.all.count }
        end
      end
    end

    context 'active recurring_active_job' do
      let(:recurring_active_job) { RecurringActiveJob::Model.create!(active: true) }

      it 'requeues job with same arguments' do
        params = { recurring_active_job_id: recurring_active_job.id, abc: 123 }

        # Allow calling the actual logic tested later
        expect(described_class).to receive(:set).and_call_original

        expect(described_class).to receive(:set).and_return(conigured_job_mock)
        expect(conigured_job_mock).to receive(:perform_later).with(hash_including(params)).and_return(double("ActiveJob::ConfiguredJob", job_id: "", queue_name: ""))

        described_class.set.perform_now(params)
      end

      it 'requeues job on same queue' do
        skip "Something's off here, it always gets called with default queue"

        queue_name = :priority

        # Allow calling the actual logic tested later
        expect(described_class).to receive(:set).with(queue: queue_name).and_call_original

        expect(described_class).to receive(:set).with(hash_including(queue: queue_name)).and_call_original

        described_class.set(queue: queue_name).perform_now(recurring_job_params)
      end

      it 'requeues job with given frequency' do
        expect(described_class).to receive(:set).with(hash_including(wait: recurring_active_job.frequency_seconds.seconds)).and_call_original

        described_class.perform_now(recurring_job_params)
      end
    end
  end
end
