require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::AdvisorCreateForm do
  before do
    load_standard_documents
    load_docyt_support
  end

  context "#save" do
    let!(:advisor_form)   { Api::Web::V1::AdvisorCreateForm }
    let!(:password)       { Faker::Lorem.characters(8) }
    let!(:short_password) { Faker::Lorem.characters(4) }

    let(:valid_save_params) {
      st_category = StandardCategory.first
      {
        'email' => Faker::Internet.email,
        'password' => password,
        'password_confirmation' => password,
        'standard_category_id' => [st_category.id]
      }
    }

    let(:invalid_save_params) {
      {
        'email' => "@#{Faker::Internet.email}@",
        'password' => short_password,
        'password_confirmation' => password,
        'standard_category_id' => 4000
      }
    }

    it 'should create an advisor when params are valid and return it #get_advisor' do
      @form = advisor_form.new(valid_save_params)

      expect { @form.save }.to change(User, :count).by(1)

      expect(@form.get_advisor.email).to eq(valid_save_params['email'])
    end

    it 'should not create an advisor when params are invalid' do
      @form = advisor_form.new(invalid_save_params)

      expect { @form.save }.not_to change(User, :count)

      expect(@form.errors.messages.keys).to eq([:email, :password_confirmation, :password])
    end
  end

end
