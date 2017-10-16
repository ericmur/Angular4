class DocumentField < BaseDocumentField
  belongs_to :document
  belongs_to :created_by, :foreign_key => 'created_by_user_id', :class_name => 'User' #Always better to use class_name instead of class as otherwise it could cause circular dependency. Since using :class => User would invoke rails code inside User.rb while loading this relationship
  after_destroy :destroy_field_value
  validates :field_id, uniqueness: { scope: :standard_document_id } #Can be nil at time of creation. Automatically filled in upon save since this column is set as AutoIncrease Sequence in PostGres.
  
  def destroy_field_value
    DocumentFieldValue.where(local_standard_document_field_id: self.field_id, document_id: self.document_id).destroy_all
  end
end
