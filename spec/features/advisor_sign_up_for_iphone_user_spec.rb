require 'rails_helper'
require 'custom_spec_helper'

feature "Sign up process for iphone user" do
  before do
    load_standard_documents
    load_docyt_support
    visit '/sign_up'
  end

  let(:email)    { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password }

  let(:invalid_password) { Faker::Lorem.characters(4) }

  let!(:iphone_advisor) { create(:advisor_iphone) }

  scenario 'Sign up with an empty input phone field', js: true, faye: true do
    find('.submit-phone-sign-up-js').click

    expect(page).to have_content('Invalid phone number')
  end

  scenario 'Success find user by phone number', js: true, faye: true do
    find_iphone_advisor

    expect(page).not_to have_content('SIGN UP')

    expect(page).to have_content('VERIFY')
    expect(page).to have_content('Resend code')
    expect(page).to have_content('Please enter it below, to verify the phone.')
    expect(page).to have_content("We have texted you a confirmation code on #{iphone_advisor.phone_normalized}")
  end

  scenario 'Redirect to sing in if advisor is setuped web app', js: true, faye: true do
    web_advisor = create(:advisor)

    fill_in 'Docyt account phone number', with: web_advisor.phone
    find('.submit-phone-sign-up-js').click

    expect(page).not_to have_content('SIGN UP')
    expect(page).to have_content('SIGN IN')
  end

  scenario 'Successfully send valid confirmation code', js: true, faye: true do
    find_iphone_advisor
    confirm_phone

    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')
  end

  scenario 'Enter invalid confirmation code', js: true, faye: true do
    find_iphone_advisor

    fill_in 'Confirmation Code', with: Faker::Number.number(6)

    find('#submit-code').click

    expect(page).to have_content('Confirmation Code is incorrect')
  end

  scenario 'Enter valid PIN', js: true, faye: true do
    find_iphone_advisor
    confirm_phone
    confirm_pin
    is_confirm_credentials_page
  end

  scenario 'Enter invalid PIN', js: true, faye: true do
    find_iphone_advisor
    confirm_phone

    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')

    pin_inputs_arr = all(".pincode-input-text")

    pin_inputs_arr.each_with_index { |val, index| pin_inputs_arr[index].set('1') }

    find('.submit-js').click

    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')
    expect(page).to have_content('PIN code is incorrect')
  end

  scenario 'Enter not a numbers for PIN', js: true, faye: true do
    find_iphone_advisor
    confirm_phone

    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')

    pin_inputs_arr = all(".pincode-input-text")

    pin_inputs_arr.each_with_index { |val, index| pin_inputs_arr[index].set('a') }

    find('.submit-js').click

    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')
    expect(page).to have_content('Please enter only 6 numbers')
  end

  scenario 'Successfully confirmation credentials for iphone advisor with change email and set password', js: true, faye: true do
    find_iphone_advisor
    confirm_phone
    confirm_pin
    is_confirm_credentials_page

    find('.change-email-link-js').click

    find('.email-input-js').set(email)
    find('.password-input-js').set(password)
    find('.password-confirmation-input-js').set(password)

    find('.submit-credentials-js').click

    is_not_credentials_page
    is_sign_in_page
  end

  scenario 'Successfully confirmation credentials for iphone advisor with set password', js: true, faye: true do
    find_iphone_advisor
    confirm_phone
    confirm_pin

    is_confirm_credentials_page

    find('.password-input-js').set(password)
    find('.password-confirmation-input-js').set(password)
    find('.submit-credentials-js').click

    is_not_credentials_page
    is_sign_in_page
  end

  scenario 'Unsuccessfully confirmation credentials for iphone advisor with invalid data', js: true, faye: true do
    find_iphone_advisor
    confirm_phone
    confirm_pin
    is_confirm_credentials_page

    find('.change-email-link-js').click

    find('.email-input-js').set("@#{Faker::Internet.email}@")
    find('.password-input-js').set(invalid_password)
    find('.password-confirmation-input-js').set(invalid_password)

    find('.submit-credentials-js').click

    expect(page).to have_content('Please enter correct email')
    expect(page).to have_content('Password too short')
  end

  scenario 'Unsuccessfully confirmation credentials for iphone advisor with exists email', js: true, faye: true do
    exists_user = create(:consumer)

    find_iphone_advisor
    confirm_phone
    confirm_pin

    is_confirm_credentials_page

    find('.change-email-link-js').click

    find('.email-input-js').set(exists_user.email)

    find('.password-input-js').set(password)
    find('.password-confirmation-input-js').set(password)

    find('.submit-credentials-js').click

    expect(page).to have_content('This email is already in use')
  end

  def find_iphone_advisor
    fill_in 'Docyt account phone number', with: iphone_advisor.phone
    find('.submit-phone-sign-up-js').click
  end

  def confirm_phone
    expect(page).to have_content('VERIFY')
    expect(page).to have_content('Resend code')
    expect(page).to have_content('Please enter it below, to verify the phone.')
    expect(page).to have_content("We have texted you a confirmation code on #{iphone_advisor.phone_normalized}")

    iphone_advisor.reload

    fill_in 'Confirmation Code', with: iphone_advisor.web_phone_confirmation_token
    find('#submit-code').click

    expect(page).not_to have_content('VERIFY')
    expect(page).not_to have_content('Resend code')
    expect(page).not_to have_content('Please enter it below, to verify the phone.')
    expect(page).not_to have_content("We have texted you a confirmation code on #{iphone_advisor.phone_normalized}")
  end

  def confirm_pin
    expect(page).to have_content('CONTINUE')
    expect(page).to have_content('Enter your Docyt app mobile PIN')

    pin_inputs_arr = all(".pincode-input-text")

    pin_inputs_arr.each_with_index { |val, index| pin_inputs_arr[index].set(iphone_advisor.pin_confirmation[index]) }

    find('.submit-js').click

    expect(page).to_not have_content('CONTINUE')
    expect(page).to_not have_content('Enter your Docyt app mobile PIN')
  end

  def is_confirm_credentials_page
    expect(page).to have_content('User name:')
    expect(page).to have_content('Set password:')
    expect(page).to have_content('Confirm password:')
  end

  def is_not_credentials_page
    expect(page).to_not have_content('User name:')
    expect(page).to_not have_content('Set password:')
    expect(page).to_not have_content('Confirm password:')
  end

  def is_sign_in_page
    expect(page).to have_content('Sign In')
    expect(page).to have_content('Remember me')
    expect(page).to have_content('SIGN IN')
  end

end
