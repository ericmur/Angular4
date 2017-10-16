FactoryGirl.define do
  factory :fax_page_one, class: 'PurchaseItem' do
    name "$0.99 for 1 page fax"
    product_identifier "docytTest.Docyt.Consumable.FaxPage1"
    price "0.99"
    fax_credit_value 1
  end

end
