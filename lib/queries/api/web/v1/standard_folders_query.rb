class Api::Web::V1::StandardFoldersQuery
  include Mixins::ClientOrGroupUserHelper

  def initialize(current_advisor, params)
    @params          = params
    @password        = params[:password]
    @current_advisor = current_advisor
    @business_id     = params[:business_id]
    @client_id       = set_client_from_params(params)
    @group_user_id   = set_group_user_from_params(params)

    @standard_folder_id = params[:standard_folder_id]

    @standard_folder_standard_documents = StandardFolderStandardDocument.arel_table
    @standard_folders                   = StandardFolder.arel_table
    @documents                          = Document.arel_table
    @document_fields                    = DocumentField.arel_table
    @document_field_values              = DocumentFieldValue.arel_table
    set_business
  end

  def get_categories
    if @params[:own_categories]
      get_categories_for_object(@current_advisor)
    elsif @business_id
      get_categories_for_object(@business)
    else
      only_category
    end
  end

  def get_category_documents
    if @business_id
      get_category_documents_for_object(@business)
    else
      get_category_documents_for_object(user(@params[:own_documents]))
    end
  end

  def get_standard_folder
    only_category.find_by(id: @params[:id])
  end

  private

  def get_category_documents_for_object(object)
    return Document.none unless object

    standard_folder = only_category.find_by(id: @standard_folder_id)
    return get_documents(object, nil) unless standard_folder

    standard_document_ids = standard_folder.standard_folder_standard_documents.pluck(:standard_base_document_id)
    get_secured_documents_if_sercured_folder(object, standard_document_ids)
  end

  def get_categories_for_object(object)
    default_query(object).where(
      @standard_folders[:id].in(get_standard_folder_ids_shared_with_advisor_sql(object))
    )
  end

  def secured_standard_folder?
    @standard_folder_id.to_i == StandardFolder::PASSWORD_FOLDER_ID
  end

  def have_access?
    @current_advisor.valid_password?(@password)
  end

  def get_secured_documents_if_sercured_folder(object, ids)
    return get_documents(object, ids) unless secured_standard_folder?

    return if secured_standard_folder? && !have_access?
    get_documents(object, ids)
  end

  def only_category
    object = set_user_object(@current_advisor, @client_id, @group_user_id)
    return StandardFolder.only_category unless object

    default_query(object).where(get_only_folders_with_documents_sql(object, @current_advisor.standard_category_id))
  end

  def get_user_owner_id(object)
    return object.id if object.class == Client && object.consumer_id.blank?

    return object.consumer_id if object.class == Client && object.consumer_id.present?

    return object.id if object.class == GroupUser && object.user_id.blank?

    return object.user_id if object.class == GroupUser && object.user_id.present?
  end

  def get_user_owner_type(object)
    return "Client" if object.class == Client && object.consumer_id.blank?

    return "Consumer" if object.class == Client && object.consumer_id.present?

    return "Consumer" if object.class == GroupUser
  end

  def get_query_params_for_user_document_types(object)
    { user_id: get_user_owner_id(object), user_type: get_user_owner_type(object) }
  end

  # Get documents
  def get_documents(object, ids)
    standard_document_ids_sql = get_sql_for_show_documents_by_category(ids)

    Document.where(standard_document_ids_sql)
      .where(id: get_shared_ids_by_object(@current_advisor, object))
  end

  # SQL parts
  def get_sql_for_show_documents_by_category(ids)
    return @documents[:standard_document_id].in(ids) if ids

    @documents[:standard_document_id].eq(nil)
  end

  def get_standard_folder_standard_documents_sql
    @standard_folder_standard_documents.project(
      @standard_folder_standard_documents[:standard_base_document_id]
    ).where(
      @standard_folder_standard_documents[:standard_folder_id].eq(@standard_folders[:id])
    )
  end

  def get_documents_count_sql(object)
    @documents.project(@documents[:id].count)
      .where(
        @documents[:standard_document_id].in(
          get_standard_folder_standard_documents_sql
        ).and(
          @documents[:id].in(
            get_shared_ids_by_object(@current_advisor, object)
          )
        )
      ).as("category_documents_count")
  end

  def get_standard_documents_ids_shared_with_advisor_sql(object)
    @documents.project(
      @documents[:standard_document_id]
    ).where(
      @documents[:id].in(
        get_shared_ids_by_object(@current_advisor, object)
      )
    )
  end

  def get_standard_folder_ids_shared_with_advisor_sql(object)
    @standard_folder_standard_documents.project(
      @standard_folder_standard_documents[:standard_folder_id]
    ).where(
      @standard_folder_standard_documents[:standard_base_document_id].in(
        get_standard_documents_ids_shared_with_advisor_sql(object)
      )
    )
  end

  def get_advisor_default_folders_ids_sql(standard_category_id)
    advisor_default_folders = AdvisorDefaultFolder.arel_table

    advisor_default_folders.project(
      advisor_default_folders[:standard_folder_id]
    ).where(
      advisor_default_folders[:standard_category_id].eq(standard_category_id)
    )
  end

  def get_only_folders_with_documents_sql(object, standard_category_id)
    @standard_folders[:id].in(
      get_standard_folder_ids_shared_with_advisor_sql(object)
    ).or(
      @standard_folders[:id].in(
        get_advisor_default_folders_ids_sql(standard_category_id)
      )
    )
  end

  def default_query(object)
    StandardFolder.select("standard_base_documents.*", get_documents_count_sql(object))
      .group('standard_base_documents.id')
      .order(rank: :asc)
  end

  def set_business
    @business ||= @current_advisor.businesses.find_by(id: @business_id) if @business_id
  end

end
