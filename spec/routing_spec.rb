# frozen_string_literal: true

ALAVETELI_TEST_THEME = 'righttoknow'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

describe 'custom routes' do
  describe 'GET /help/house_rules' do
    it 'routes to help#house_rules' do
      expect(get: '/help/house_rules').to route_to(controller: 'help', action: 'house_rules')
    end
  end

  describe 'GET /people' do
    it 'redirects to /statistics#people' do
      expect(get: '/people').to redirect_to('/statistics#people')
    end
  end
end
