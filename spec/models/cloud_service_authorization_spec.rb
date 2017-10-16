require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe CloudServiceAuthorization, :type => :model do
  before(:each) do
    stub_docyt_support_creation
  end
  
  let(:subject) { create(:cloud_service_authorization) }

  it { expect(subject).to validate_presence_of(:token) }
  it { expect(subject).to validate_presence_of(:uid) }
  it { expect(subject).to belong_to(:user) }
  it { expect(subject).to belong_to(:cloud_service) }
end
