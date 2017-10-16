FactoryGirl.define do
  factory :group_user do
    name  { Faker::Name.name }
    email  { Faker::Internet.email }
    phone  { FactoryGirl.generate(:phone) }
    user { create(:consumer) }
    label  'Spouse'
    group
    business
  end

  factory :group_user_custom_consumer, class: "GroupUser" do
    name  { Faker::Name.first_name }
    email { Faker::Internet.email }
    phone { FactoryGirl.generate(:phone) }
    label { [GroupUser::SPOUSE, GroupUser::KID].sample }
    user
    group
    business
  end

  factory :unconnected_group_user, class: "GroupUser" do
    name  { Faker::Name.first_name }
    email { Faker::Internet.email }
    phone { FactoryGirl.generate(:phone) }
    # label { [GroupUser::SPOUSE, GroupUser::KID, GroupUser::EMPLOYEE, GroupUser::CONTRACTOR].sample }
    label { [GroupUser::SPOUSE, GroupUser::KID].sample }
    business
  end

  factory :connected_group_user, class: "GroupUser" do
    user  { create(:consumer) }
    label { [GroupUser::SPOUSE, GroupUser::KID].sample }
    group
    business
  end
end
