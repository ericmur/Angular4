require 'active_support/concern'

module FolderSettingGenerator
  extend ActiveSupport::Concern

  FOLDER='folder'
  FLAT='flat'

  def should_displayed_base_doc_ids
    if self.user_id.present?
      displayed_documents = Document.categorized.select('standard_document_id').joins(:document_owners).where(document_owners: { owner_id: self.user_id, owner_type: User.to_s })
    else
      displayed_documents = Document.categorized.select('standard_document_id').joins(:document_owners).where(document_owners: { owner_id: self.id, owner_type: self.class.to_s })
    end
    base_doc_ids = []
    base_doc_ids += displayed_documents.map{|d| d.standard_document.standard_folder_standard_documents.map(&:standard_folder_id) }.flatten.uniq
    base_doc_ids += displayed_documents.select('standard_document_id').map{|d| d.standard_document_id }.flatten.uniq
    base_doc_ids
  end

  def generate_folder_settings(parent_owner, label=nil)
    account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
    groups = YAML.load(ERB.new(File.read("#{Rails.root}/config/standard_groups.yml.erb")).result)["groups"]
    flat_structure = nil

    if label.present?
      groups["content"].each do |group_name, group_hash|
        group_hash["labels"].each do |account_type, group_user_labels|
          next if account_types[account_type]["id"].to_i != parent_owner.consumer_account_type_id
          if group_user_labels.include?(label)
            flat_structure = group_hash["flat_structure"][label]
          end
        end
      end
    end

    flat_structure_needed = !flat_structure.blank?
    if flat_structure_needed
      generate_flat_structure_settings(parent_owner, flat_structure)
    else
      generate_folder_structure_settings(parent_owner)
    end
  end


  def generate_flat_structure_settings(parent_owner, structure)
    cleanup_user_folder_settings
    standard_documents_ids = StandardDocument.only_system.select('id').where(name: structure.map(&:titleize)).map(&:id)
    StandardDocument.only_system.select('id').each do |standard_document|
      displayed = standard_documents_ids.include?(standard_document.id)
      fs = parent_owner.user_folder_settings.where(folder_owner: self, standard_base_document_id: standard_document.id).first
      if fs.present?
        fs.update_column(:displayed, displayed)
      else
        parent_owner.user_folder_settings.create(folder_owner: self, standard_base_document_id: standard_document.id, displayed: displayed)
      end
    end
    self.update_column(:structure_type, FLAT)
  end

  def generate_folder_structure_settings(parent_owner)
    folders = StandardBaseDocumentAccountType.where(:consumer_account_type_id => ConsumerAccountType::INDIVIDUAL)
    std_folders_not_allowed = StandardFolder.only_system.only_category.where.not(:id => folders.map(&:standard_folder_id))

    cleanup_user_folder_settings

    (folders + std_folders_not_allowed).each do |folder|
      std_folder_id = folder.is_a?(StandardFolder) ? folder.id : folder.standard_folder_id
      user_folder_setting = parent_owner.user_folder_settings.where(:standard_base_document_id => std_folder_id, :folder_owner => self).first
      folder_show = folder.is_a?(StandardFolder) ? false : folder.show
      if user_folder_setting.nil?
        user_folder_setting = parent_owner.user_folder_settings.build(:standard_base_document_id => std_folder_id, :folder_owner => self, :displayed => folder_show)
      else
        user_folder_setting.displayed = folder_show
      end
      user_folder_setting.save!
    end
    self.update_column(:structure_type, FOLDER)
  end

  def cleanup_user_folder_settings
    max_base_doc_id = StandardBaseDocument.where(consumer_id: nil).maximum(:id)
    user_folder_settings.where(folder_owner: self).where('standard_base_document_id <= ? AND standard_base_document_id NOT IN (?)', max_base_doc_id, should_displayed_base_doc_ids).destroy_all
  end

end
