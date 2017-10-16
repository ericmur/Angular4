require 'rails_helper'
require 'custom_spec_helper'

feature "Sign up process" do
  before do
    load_standard_documents
    load_docyt_support
    visit '/sign_up'
  end

  let(:email)    { Faker::Internet.safe_email }
  let(:password) { Faker::Lorem.characters(8) }

  let(:fill_email_and_password) {
    fill_in 'Email',    with: email
    fill_in 'Password', with: password
    fill_in 'Confirm Password', with: password
  }

  let(:stub_twilio) {
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
  }

  scenario 'Sign up with an empty input fields', js: true, faye: true do
    find('.submit-web-sign-up-js').click

    expect(page).to have_content('Password too short')
    expect(page).to have_content('Please enter correct email')
  end

  scenario 'Sign up without selecting service provider', js: true, faye: true do
    fill_email_and_password
    find('.submit-web-sign-up-js').click

    expect(page).not_to have_content('Please enter correct email')
    expect(page).not_to have_content('Password too short')
  end

  scenario 'Sign up without email', js: true, faye: true do
    fill_in 'Password', with: password
    fill_in 'Confirm Password', with: password
    find('.submit-web-sign-up-js').click

    expect(page).to have_content('Please enter correct email')
    expect(page).not_to have_content('Password too short')
  end

  scenario 'Sign up without password', js: true, faye: true do
    fill_in 'Email', with: Faker::Internet.safe_email
    find('.submit-web-sign-up-js').click

    expect(page).to have_content('Password too short')
    expect(page).not_to have_content('Please enter correct email')
  end

  scenario 'Sign up with different passwords', js: true, faye: true do
    fill_in 'Email', with: Faker::Internet.safe_email
    fill_in 'Password', with: Faker::Internet.password
    fill_in 'Confirm Password', with: Faker::Internet.password
    find('.submit-web-sign-up-js').click

    expect(page).to have_content("Password doesn't match")
    expect(page).not_to have_content('Please enter correct email')
  end

  scenario 'Success sign up', js: true, faye: true do
    fill_email_and_password
    find('.submit-web-sign-up-js').click

    expect(page).to have_content('For additional security, please provide a cell-phone number.')
    expect(page).not_to have_content('Password too short')
    expect(page).not_to have_content('Please enter correct email')
  end

  scenario 'Sign up with valid phone and valid confirmation code without email confirmation', js: true, faye: true do
    stub_twilio
    fill_email_and_password

    find('.submit-web-sign-up-js').click
    fill_in 'Cell Phone', with: FactoryGirl.generate(:phone)
    find('#submit-phone').click
    expect(page).to have_content('We have texted you a confirmation code on')
    confirmation_token = User.where(email: email).first.phone_confirmation_token

    fill_in 'Confirmation Code', with: confirmation_token
    find('#submit-code').click

    expect(page).not_to have_content('We have texted you a confirmation code on')

    expect(page).to have_content("We have sent a link to your email: #{email}. Please validate this email by clicking on that link.")
  end

  scenario 'Success sign up with valid phone and valid confirmation code with email confirmation', js: true, faye: true do
    stub_twilio
    fill_email_and_password
    find('.submit-web-sign-up-js').click

    fill_in 'Cell Phone', with: FactoryGirl.generate(:phone)
    find('#submit-phone').click

    expect(page).to have_content('We have texted you a confirmation code on')

    advisor = User.where(email: email).first
    confirmation_token = advisor.phone_confirmation_token

    fill_in 'Confirmation Code', with: confirmation_token
    find('#submit-code').click

    expect(page).not_to have_content('We have texted you a confirmation code on')
    expect(page).to have_content("We have sent a link to your email: #{email}. Please validate this email by clicking on that link.")

    advisor.confirm_email
    visit '/clients'

    expect(page).not_to have_content("We have sent a link to your email: #{advisor.email}. Please validate this email by clicking on that link.")
    expect(page).to have_content("Congratulations! You have successfully signed up for your Docyt web account")
    expect(page).to have_content("To get started, complete your account details below.")
    expect(page).to have_content("Complete your profile")
    expect(page).to have_content("Select plan")
  end

  scenario 'Success sign up with valid phone and invalid confirmation code', js: true, faye: true do
    stub_twilio
    fill_email_and_password
    find('.submit-web-sign-up-js').click

    fill_in 'Cell Phone', with: FactoryGirl.generate(:phone)
    find('#submit-phone').click
    expect(page).to have_content('We have texted you a confirmation code on')
    fill_in 'Confirmation Code', with: Faker::Code.ean
    find('#submit-code').click
    expect(page).to have_content('Confirmation Code is incorrect')
  end

  scenario 'Success sign up with invalid phone', js: true, faye: true do
    stub_request(:any, /.*amazonaws.com.*/).to_return(status: 200)
    fill_email_and_password
    find('.submit-web-sign-up-js').click

    fill_in 'Cell Phone', with: Faker::PhoneNumber.phone_number + '0000'
    find('#submit-phone').click
    expect(page).to have_content('Phone number is incorrect')
  end
end
