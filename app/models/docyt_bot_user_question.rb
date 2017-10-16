class DocytBotUserQuestion < ActiveRecord::Base
  belongs_to :user
  serialize :document_ids, Array
  serialize :field_ids, Array

  def self.store_asked_question(user, ctx)
    question = DocytBotUserQuestion.new
    question.query_string = ctx[:text]
    question.intent       = ctx[:intent]
    question.user_id      = user.id
    question.phone        = user.phone_normalized
    question.document_ids = ctx[:document_ids].uniq unless ctx[:document_ids].nil?
    question.field_ids    = ctx[:field_ids].map{|k,_|k}.uniq unless ctx[:field_ids].nil?
    question.save
  end
end
