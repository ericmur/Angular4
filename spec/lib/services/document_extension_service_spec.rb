require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe DocumentExtensionService do
  let!(:service) { DocumentExtensionService }

  context '#pdf_file?' do
    it 'should return true if pdf mime type' do
      result = service.new('application/pdf', "#{Faker::Lorem.word}.pdf").pdf_file?

      expect(result).to be_truthy
    end

    it 'should return false if not pdf mime type' do
      result = service.new("#{Faker::File.mime_type}", "#{Faker::Lorem.word}.txt").pdf_file?

      expect(result).to be_falsey
    end
  end

  context '#image_file?' do
    it 'should return true if image mime type' do
      result = service.new('image/jpeg').image_file?

      expect(result).to be_truthy
    end

    it 'should return true if image mime type' do
      result = service.new('image/gif').image_file?

      expect(result).to be_truthy
    end

    it 'should return true if image mime type' do
      result = service.new('image/png').image_file?

      expect(result).to be_truthy
    end

    it 'should return false if not image mime type' do
      result = service.new('application/pdf').image_file?

      expect(result).to be_falsey
    end
  end

  context '#microsoft_file?' do
    it 'should return true if microsoft mime type' do
      result = service.new('application/msword').microsoft_file?

      expect(result).to be_truthy
    end

    it 'should return true if microsoft mime type' do
      result = service.new('application/vnd.ms-excel').microsoft_file?

      expect(result).to be_truthy
    end

    it 'should return true if microsoft mime type' do
      result = service.new('application/vnd.ms-powerpoint').microsoft_file?

      expect(result).to be_truthy
    end

    it 'should return false if not microsoft mime type' do
      result = service.new('application/pdf').microsoft_file?

      expect(result).to be_falsey
    end
  end
end
