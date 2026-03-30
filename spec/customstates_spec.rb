# frozen_string_literal: true

ALAVETELI_TEST_THEME = 'righttoknow'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

describe InfoRequestCustomStates do
  describe '.theme_extra_states' do
    it 'returns the transferred state' do
      expect(InfoRequest.theme_extra_states).to eq(['transferred'])
    end
  end

  describe '.theme_display_status' do
    it 'returns the display string for the transferred state' do
      expect(InfoRequest.theme_display_status('transferred')).to eq('Transferred.')
    end

    it 'raises an error for unknown statuses' do
      expect { InfoRequest.theme_display_status('unknown_state') }
        .to raise_error(RuntimeError, /unknown status/)
    end
  end

  describe '#theme_calculate_status' do
    it 'delegates to base_calculate_status' do
      info_request = FactoryBot.build(:info_request)
      expect(info_request).to receive(:base_calculate_status).and_call_original
      info_request.theme_calculate_status
    end
  end
end

describe RequestControllerCustomStates do
  describe '#theme_describe_state' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      info_request.described_state = 'transferred'
      info_request.save!
    end

    it 'sets a flash notice about the transfer' do
      using_admin_role do
        post :describe_state, params: {
          id: info_request.url_title,
          incoming_message: { described_state: 'transferred' }
        }
      end
      expect(flash[:notice]).to match(/transferred/i)
    end
  end
end
