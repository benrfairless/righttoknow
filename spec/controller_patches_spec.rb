# frozen_string_literal: true

ALAVETELI_TEST_THEME = 'righttoknow'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

describe HelpController do
  describe 'GET house_rules' do
    before { get :house_rules }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'sets @history to a HelpPageHistory instance' do
      expect(assigns(:history)).to be_a(HelpPageHistory)
    end
  end

  describe 'set_history before_action' do
    context 'when the action has a template' do
      it 'assigns @history' do
        get :house_rules
        expect(assigns(:history)).not_to be_nil
      end
    end

    context 'when the action has no template' do
      it 'does not raise an error' do
        # Simulate a missing template by calling an action without one.
        # The before_action rescues ActionView::MissingTemplate silently.
        allow_any_instance_of(ActionView::LookupContext)
          .to receive(:find_template).and_raise(ActionView::MissingTemplate.new([], '', [], false, []))

        expect { get :house_rules }.not_to raise_error
      end

      it 'does not set @history' do
        allow_any_instance_of(ActionView::LookupContext)
          .to receive(:find_template).and_raise(ActionView::MissingTemplate.new([], '', [], false, []))

        get :house_rules
        expect(assigns(:history)).to be_nil
      end
    end
  end
end
