require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::DocumentsController do
  context "#index" do
    it 'should return document json cache with proper serializer attributes'
    it 'should include standard document fields'
    it 'should include encrypted field but not the value'
  end
end