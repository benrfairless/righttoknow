# frozen_string_literal: true

# If defined, ALAVETELI_TEST_THEME will be loaded in config/initializers/theme_loader
ALAVETELI_TEST_THEME = 'righttoknow'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

describe HelpPageHistory do
  describe '#commits_url' do
    subject { described_class.new(template).commits_url }

    context 'with a custom help page' do
      let(:template) do
        double(identifier: 'lib/themes/righttoknow/lib/views/' \
                           'help/house_rules.html.erb')
      end

      it do
        is_expected.to eq('https://github.com/openaustralia/righttoknow/' \
                          'commits/production/lib/views/help/house_rules.html.erb')
      end
    end

    context 'with a different help page' do
      let(:template) do
        double(identifier: 'lib/themes/righttoknow/lib/views/help/about.html.erb')
      end

      it do
        is_expected.to eq('https://github.com/openaustralia/righttoknow/' \
                          'commits/production/lib/views/help/about.html.erb')
      end
    end

    context 'with a help page in a nested path' do
      let(:template) do
        double(identifier: '/var/www/alaveteli/lib/themes/righttoknow/lib/views/' \
                           'help/privacy.html.erb')
      end

      it 'uses only the filename' do
        is_expected.to eq('https://github.com/openaustralia/righttoknow/' \
                          'commits/production/lib/views/help/privacy.html.erb')
      end
    end
  end
end
