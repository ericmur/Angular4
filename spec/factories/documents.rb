FactoryGirl.define do
  factory :document do
    cloud_service_authorization
    file_content_type 'application/pdf'
    original_file_name { "#{Faker::Lorem.word}.pdf" }
    original_file_key  { "#{Faker::Lorem.word}.pdf" }
    final_file_key     { "#{Faker::Lorem.word}.pdf" }

    transient do
      with_owner_list []
    end

    after :build do  |document, evaluator|
      evaluator.with_owner_list.each do |owner|
        document.document_owners.build(owner: owner)
      end
    end
  end

  trait :with_uploader_and_owner do
    after :build do |document|
      document.uploader = FactoryGirl.create(:consumer)
      document.document_owners << DocumentOwner.new(
        owner_id: document.uploader.id,
        owner_type: 'User'
      )
    end
  end

  trait :with_owner do
    after :build do |document|
      document.document_owners << DocumentOwner.new(
        owner_id: document.uploader.id,
        owner_type: 'User'
      )
    end
  end

  trait :with_std_doc do
    after :build do |document|
      document.standard_document = FactoryGirl.create(:standard_document, :with_standard_document_fields, :with_standard_folder)
    end
  end

  trait :attached_to_email do
    after :build do |document|
      document.uploader = FactoryGirl.create(:advisor)
      document.email = FactoryGirl.create(:email)
      document.source = 'ForwardedEmail'
      document.document_owners << DocumentOwner.new(
        owner_id: document.uploader.id,
        owner_type: 'User'
      )
    end
  end

  trait :with_system_symmetric_key do
    after :build do |document|
      s3_encryptor = S3::DataEncryption.new
      document.symmetric_keys.build(
        :created_by_user_id => nil,
        :key => s3_encryptor.encryption_key,
        :iv => s3_encryptor.encryption_iv,
        :created_for_user_id => nil
      )
    end
  end

  trait :with_standard_document do
    after :build do |document|
      document.standard_document = FactoryGirl.create(:standard_document, :with_standard_document_fields, :with_standard_folder)
      document.uploader = FactoryGirl.create(:consumer)
      document.document_owners << DocumentOwner.new(
        owner_id: document.uploader.id,
        owner_type: 'User'
      )
    end
  end

  trait :specific_extension do
    after :build do |document|
      document.original_file_key = document.original_file_name
      document.final_file_key    = document.original_file_name
    end
  end

end
