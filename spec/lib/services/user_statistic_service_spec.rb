require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe UserStatisticService do
  before(:each) do
    load_startup_keys
    load_standard_documents
    load_docyt_support
  end

  let!(:consumer) { create(:consumer, :email => 'sid@vayuum.com', :pin => '123456', :pin_confirmation => '123456') }
  let!(:advisor) { create(:advisor) }

  context '#set_last_logged_in_web_app' do
    it 'should successfully set last logged in web app' do
      UserStatisticService.new(advisor).set_last_logged_in_web_app
      user_statistic = advisor.user_statistic
      expect(user_statistic.last_logged_in_web_app).not_to eq(nil)
    end
  end

  context '#set_last_logged_in_iphone_app' do
    it 'should successfully set last logged in iphone app' do
      UserStatisticService.new(consumer).set_last_logged_in_iphone_app
      user_statistic = consumer.user_statistic
      expect(user_statistic.last_logged_in_iphone_app).not_to eq(nil)
    end
  end
end
