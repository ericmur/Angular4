class BaseDocumentField < ActiveRecord::Base
  self.table_name = "standard_document_fields"
  serialize :data_type_values, Array

  ALERT_DATA_TYPES = ['date', 'expiry_date', 'due_date']
  PAID_FIELD_NAME = 'Paid?'
  SPEECH_TYPES = ['spell-out']
  BUSINESS_RECEIPT_TYPES_VALUES = ["Meal", "Travel", "Gift", "Gas", "Mileage", "Other"]
  PERSONAL_RECEIPT_TYPES_VALUES = ["Medical", "Dental", "Childcare", "Education", "Groceries", "Household", "Financial", "Other"]

  has_many :notify_durations, dependent: :destroy, :foreign_key => 'standard_document_field_id'
  has_many :aliases, dependent: :destroy, :as => :aliasable
  validates :name, :presence => true
  validates :data_type, presence: true, inclusion: { in: %w(int float date expiry_date due_date year string text zip state country boolean url currency phone array) }
  validates :field_id, :uniqueness => { :scope => :standard_document_id }
end
