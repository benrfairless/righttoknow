# frozen_string_literal: true

ALAVETELI_TEST_THEME = 'righttoknow'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

describe PublicBody do
  describe '#jurisdiction' do
    subject { body.jurisdiction }

    let(:body) { PublicBody.new }

    {
      'ACT' => :act,
      'NSW' => :nsw,
      'NT'  => :nt,
      'QLD' => :qld,
      'SA'  => :sa,
      'TAS' => :tas,
      'VIC' => :vic,
      'WA'  => :wa,
      'federal' => :federal
    }.each do |tag, expected_jurisdiction|
      context "tagged #{tag}" do
        before do
          allow(body).to receive(:has_tag?).and_return(false)
          allow(body).to receive(:has_tag?).with(tag).and_return(true)
        end

        it { is_expected.to eq(expected_jurisdiction) }
      end
    end

    context 'with no jurisdiction tag' do
      before { allow(body).to receive(:has_tag?).and_return(false) }

      it { is_expected.to be_nil }
    end
  end

  describe '#reply_late_after_days' do
    subject { body.reply_late_after_days }

    let(:body) { PublicBody.new }

    {
      nsw: 20, tas: 20,
      qld: 25,
      federal: 30, act: 30, nt: 30, sa: 30,
      vic: 45, wa: 45
    }.each do |jurisdiction, expected_days|
      context "in #{jurisdiction} jurisdiction" do
        before { allow(body).to receive(:jurisdiction).and_return(jurisdiction) }

        it { is_expected.to eq(expected_days) }
      end
    end

    context 'with unknown jurisdiction' do
      before { allow(body).to receive(:jurisdiction).and_return(nil) }

      it 'falls back to AlaveteliConfiguration' do
        is_expected.to eq(AlaveteliConfiguration.reply_late_after_days)
      end
    end
  end

  describe '#working_or_calendar_days' do
    subject { body.working_or_calendar_days }

    let(:body) { PublicBody.new }

    [:nsw, :tas, :qld].each do |jurisdiction|
      context "in #{jurisdiction} jurisdiction" do
        before { allow(body).to receive(:jurisdiction).and_return(jurisdiction) }

        it { is_expected.to eq('working') }
      end
    end

    [:federal, :act, :nt, :sa, :vic, :wa, nil].each do |jurisdiction|
      context "in #{jurisdiction.inspect} jurisdiction" do
        before { allow(body).to receive(:jurisdiction).and_return(jurisdiction) }

        it { is_expected.to eq('calendar') }
      end
    end
  end

  describe '#legislation' do
    subject { body.legislation.key }

    let(:body) { PublicBody.new }

    context 'in NSW jurisdiction' do
      before { allow(body).to receive(:jurisdiction).and_return(:nsw) }

      it { is_expected.to eq('gipa') }
    end

    [:qld, :tas].each do |jurisdiction|
      context "in #{jurisdiction} jurisdiction" do
        before { allow(body).to receive(:jurisdiction).and_return(jurisdiction) }

        it { is_expected.to eq('rti') }
      end
    end

    [:federal, :act, :nt, :sa, :vic, :wa, nil].each do |jurisdiction|
      context "in #{jurisdiction.inspect} jurisdiction" do
        before { allow(body).to receive(:jurisdiction).and_return(jurisdiction) }

        it { is_expected.to eq('foi') }
      end
    end
  end

  describe '#info_requests_hidden_count' do
    it 'counts requests where prominence is not normal' do
      body = FactoryBot.create(:public_body)
      FactoryBot.create(:info_request, public_body: body, prominence: 'normal')
      FactoryBot.create(:info_request, public_body: body, prominence: 'hidden')
      FactoryBot.create(:info_request, public_body: body, prominence: 'requester_only')

      expect(body.info_requests_hidden_count).to eq(2)
    end

    it 'returns zero when all requests have normal prominence' do
      body = FactoryBot.create(:public_body)
      FactoryBot.create(:info_request, public_body: body, prominence: 'normal')

      expect(body.info_requests_hidden_count).to eq(0)
    end
  end
end

describe InfoRequest do
  describe '#date_response_required_by' do
    let(:public_body) do
      instance_double(PublicBody,
                      reply_late_after_days: 30,
                      working_or_calendar_days: 'calendar')
    end
    let(:sent_at) { Date.new(2024, 1, 1) }
    let(:info_request) do
      InfoRequest.new(public_body: public_body).tap do |r|
        allow(r).to receive(:date_initial_request_last_sent_at).and_return(sent_at)
      end
    end

    it 'delegates to Holiday.due_date_from with the body reply deadline and day type' do
      expect(Holiday).to receive(:due_date_from).with(
        sent_at,
        public_body.reply_late_after_days,
        public_body.working_or_calendar_days
      )
      info_request.date_response_required_by
    end

    it 'returns the date calculated by Holiday.due_date_from' do
      expected_date = Date.new(2024, 1, 31)
      allow(Holiday).to receive(:due_date_from).and_return(expected_date)
      expect(info_request.date_response_required_by).to eq(expected_date)
    end
  end
end

describe Legislation do
  describe '.all' do
    subject { described_class.all }

    it 'includes FOI' do
      expect(subject.map(&:key)).to include('foi')
    end

    it 'includes GIPA (NSW specific)' do
      expect(subject.map(&:key)).to include('gipa')
    end

    it 'includes RTI (QLD/TAS specific)' do
      expect(subject.map(&:key)).to include('rti')
    end

    it 'includes EIR' do
      expect(subject.map(&:key)).to include('eir')
    end
  end
end
