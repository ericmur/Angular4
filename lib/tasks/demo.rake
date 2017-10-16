# this task sets-up everything neccessary for demo of new features

namespace :demo do
  task setup: :environment do
    chat = Chat.create()

    advisor1 = Advisor.create(email: 'test1@demo.org', password: '11223344', password_confirmation: '11223344')
    advisor1.consumers << FactoryGirl.create(:consumer)
    chat.users << advisor1

    advisor2 = Advisor.create(email: 'test2@demo.org', password: '11223344', password_confirmation: '11223344')
    chat.users << advisor2

    welcome_message = Message.create(sender_id: advisor1.id, chat_id: chat.id, text: 'Welcome to faye-powered chat')
    chat.messages << welcome_message
  end
end
