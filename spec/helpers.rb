module Helpers
  module DocumentHelper
    def load_standard_documents(doc_name = nil, biz_doc_name = nil)
      doc_name ||= 'standard_base_documents_structure1.json'

      file_content = File.read("#{Rails.root}/spec/data/#{doc_name}")
      File.stub(:read).and_call_original
      File.stub(:read).with("#{Rails.root}/config/standard_base_documents_structure.json").and_return(file_content)

      if biz_doc_name
        file_content = File.read("#{Rails.root}/spec/data/#{biz_doc_name}")
        File.stub(:read).and_call_original
        File.stub(:read).with("#{Rails.root}/config/standard_base_documents_business_structure.json").and_return(file_content)
      end

      ConsumerAccountType.load
      StandardBaseDocument.load
    end

    def load_standard_groups
      StandardGroup.create(:name => StandardGroup::FAMILY)
    end

    def load_docyt_support(doc_name_standard_documents_structure = nil)
      File.stub(:read).and_call_original

      doc_name = 'standard_categories1.json'

      file_content = File.read("#{Rails.root}/spec/data/#{doc_name}")
      File.stub(:read).with("#{Rails.root}/config/standard_categories.json.erb").and_return(file_content)

      doc_name_standard_documents_structure ||= 'standard_base_documents_structure1.json'

      file_content = File.read("#{Rails.root}/spec/data/#{doc_name_standard_documents_structure}")
      File.stub(:read).with("#{Rails.root}/config/standard_base_documents_structure.json").and_return(file_content)

      StandardCategory.load
      FactoryGirl.create(:docyt_support_advisor)
    end
  end

  module UserHelper
    def setup_logged_in_consumer(user = nil, pin = nil)
      if user
        @user = user
        @hsh = user.password_hash(pin)
      else
        @user_pin = '123456'
        @user = FactoryGirl.create(:consumer, :pin => @user_pin, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
        if ConsumerAccountType.count == 0
          ConsumerAccountType.load
        end
        @user.update_column(:consumer_account_type_id, ConsumerAccountType.first.id)
        verify_user_email(@user)
        @hsh = @user.password_hash(@user_pin)
        @user.reload
      end
      @device = FactoryGirl.create(:device, :user_id => @user.id)
      Rails.set_user_password_hash(nil)
      token = double(:acceptable? => true, :resource_owner_id => @user.id)
      controller.stub(:doorkeeper_token) { token }
      controller.stub(:current_user) { @user }
    end

    def verify_user_email(user)
      User.verify_email_token(user.email_confirmation_token)
      user.reload
    end

    def stub_docyt_support_creation
      allow_any_instance_of(User).to receive(:connect_docyt_support_advisor).and_return(true)
    end

  end

  module AdvisorHelper
    def login_as(advisor)
      allow(User).to receive(:find_by).and_return(advisor)
    end
  end

  module RailsStartupHelper
    def load_startup_keys(options = { })
      Rails.stub(:startup_password_hash) { options[:password_hash] ? options[:password_hash] : "1234567890" }
      Rails.stub(:private_key) { options[:private_key] ? options[:private_key] : File.read('spec/data/id_rsa.test-startup.vayuum.pem') }
      Rails.stub(:public_key) { options[:public_key] ? options[:public_key] : File.read('spec/data/id_rsa.test-startup.vayuum.public.pem') }
    end
  end

  module FileHelper
    def generate_sample_file(filename='file.txt', byte_count=1024, byte_size=1024)
      `dd if=/dev/zero of=#{filename} count=#{byte_count} bs=#{byte_size} 2>&1`
    end
  end
end
