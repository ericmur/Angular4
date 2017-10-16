require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe CloudServicePath, :type => :model do
  before(:each) do
    stub_docyt_support_creation
  end
  
  it { expect(subject).to validate_presence_of(:path) }
  it { expect(subject).to belong_to(:consumer) }
  it { expect(subject).to belong_to(:cloud_service_authorization) }

  it '#sync_data' do
    service_path = CloudServicePath.new(
                                        consumer_id: create(:user).id,
                                        cloud_service_authorization: create(:cloud_service_authorization),
                                        path: '/test/path',
                                        path_display_name: '/test/path'
                                        )

    expect(PullDocumentsByCloudServicePathJob).to receive(:perform_later)

    service_path.save
    service_path.sync_data
  end
end
