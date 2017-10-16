require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::SecureDocumentsController do
  context "#index" do
    it 'should list only encrypted standard document fields'
  end
end