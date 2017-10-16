require 'rails_helper'

RSpec.describe CloudService, :type => :model do
  it { expect(subject).to validate_presence_of(:name) }
end