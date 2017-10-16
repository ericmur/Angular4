FactoryGirl.define do
  sequence :page_num do |n|
    n
  end

  factory :page do
    page_num
    document               { FactoryGirl.create(:document, :with_uploader_and_owner) }
    s3_object_key          { "#{Faker::Lorem.word}.jpg" }
    original_s3_object_key { "#{Faker::Lorem.word}.jpg" }
    original_file_md5      'd41d8cd98f00b204e9800998ecf8427e'
    final_file_md5         '49f0bad299687c62334182178bfd75d8'
    state                  'uploaded'
  end
end
