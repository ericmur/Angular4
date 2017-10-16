class Api::Web::V1::DocumentsQuery
  include Mixins::ClientOrGroupUserHelper

  DOCUMENTS_PER_PAGE = 20

  def initialize(current_advisor, params)
    @current_advisor = current_advisor
    @client_id       = set_client_from_params(params)
    @group_user_id   = set_group_user_from_params(params)
    @business_id     = params[:business_id]
    @per_page        = params[:per_page] || DOCUMENTS_PER_PAGE
    @page            = params[:page] || 1
    @params          = params
  end

  def get_documents
    if @params[:for_support]
      get_documents_for_support
    else
      get_documents_for_object
    end
  end

  def get_document
    object = set_user_object(@current_advisor, @client_id, @group_user_id)
    return unless object

    Document.where(:id => get_shared_ids_by_object(@current_advisor, object)).find_by(id: @params[:id])
  end

  def get_attached_documents
    @current_advisor.uploaded_documents_via_email_for_clients
  end

  def get_documents_count
    object = set_user_object(@current_advisor, @client_id, @group_user_id)
    get_shared_ids_by_object(@current_advisor, object).count
  end

  def get_all_documents_ids
    object = set_user_object(@current_advisor, @client_id, @group_user_id)

    if object.user_id
      group_users = GroupUser.joins(:group).where(groups: { owner_id: object.user_id })
      docs_ids = group_users.map { |g| get_shared_ids_by_object(@current_advisor, g) }.flatten
      group_users_docs_ids = SymmetricKey.for_user_access(object.user_id).where(:document_id => docs_ids).pluck(:document_id)

      object_docs_ids = get_shared_ids_by_object(@current_advisor, object)

      return (object_docs_ids + group_users_docs_ids).uniq
    else #If client is not connected, then there are no contacts of client to fetch
      return get_shared_ids_by_object(@current_advisor, object)
    end
  end

  #This method will get the documents count for all the documents of the client as well as the documents of their contacts that are shared with service provider
  def get_all_documents_count
    get_all_documents_ids.count
  end

  #This method will get the documents count for all the documents uploaded by the client. This is just for showing this statistic in Client detail to DocytSupport service provider
  def get_all_uploaded_documents_count
    client = @current_advisor.clients_as_advisor.find_by(id: @client_id)
    if client.consumer_id
      Document.where(:consumer_id => client.consumer_id).count
    else
      client.document_ownerships.count
    end
  end

  def search_documents
    if @client_id
      client = @current_advisor.clients_as_advisor.find_by(id: @client_id)
      return Document.none unless client
      document_ids = []
      if @params[:contact_id].blank?
        document_ids = Api::Web::V1::SymmetricKeyQuery.new(@current_advisor, { :id => @client_id, :type => 'Client' }).get_documents.pluck(:id)
      else #We are looking at the folders of the client so should only search within client's documents
        document_ids = client.documents_ids_shared_with_advisor
      end
    else
      group_user = get_group_user(@current_advisor, @group_user_id)
      return Document.none unless group_user
      document_ids = group_user.documents_ids_shared_with_user(@current_advisor)
    end

    Document.joins(
      "LEFT JOIN
        standard_base_documents
       ON
        standard_base_documents.id = documents.standard_document_id
       LEFT JOIN
        standard_document_fields
       ON
        standard_document_fields.standard_document_id = standard_base_documents.id

       ")
      .where("
        (
          documents.id IN (:document_ids)
          AND
          documents.standard_document_id IS NOT NULL
          AND
          standard_base_documents.name ILIKE :search_data
        )
        OR
        (
          documents.id IN (:document_ids)
          AND
          documents.original_file_name ILIKE :search_data
          AND
          documents.standard_document_id IS NULL
        )",
        search_data: "%#{@params[:search_data]}%", document_ids: document_ids)
      .select("documents.id, documents.original_file_name, documents.created_at,
        standard_base_documents.name AS standard_document_name, (
          SELECT
            sbd.name
          FROM
            standard_base_documents sbd
          WHERE
            sbd.id = (
              SELECT
                standard_folder_standard_documents.standard_folder_id
              FROM
                standard_folder_standard_documents
              WHERE
                standard_folder_standard_documents.standard_base_document_id = standard_base_documents.id
              GROUP BY
                standard_folder_standard_documents.id
              LIMIT 1
            )
        ) AS standard_folder_name,
        (
          SELECT
            sdf.field_id
          FROM
            standard_document_fields sdf
          WHERE
            sdf.document_id = documents.id
            OR
            sdf.standard_document_id = documents.standard_document_id
          ORDER BY sdf.field_id ASC
          LIMIT 1
        ) AS standard_field_id_1,
        (
          SELECT
            sdf.field_id
          FROM
            standard_document_fields sdf
          WHERE
            sdf.document_id = documents.id
            OR
            sdf.standard_document_id = documents.standard_document_id
          ORDER BY sdf.field_id ASC
          LIMIT 1
          OFFSET 1
        ) AS standard_field_id_2").distinct
  end

  def get_documents_for_contact
    object = user(@params[:own_documents])
    return unless object

    Document.where(id: get_shared_ids_by_object(@current_advisor, object))
  end


  def get_document_uploaded_via_email
    @current_advisor.uploaded_document_via_email_for_client(@params[:id])
  end

  def pages_count
    @pages_count
  end

  private

  def get_documents_for_support
    return Document.none unless @params[:only_categorized] && @current_advisor.docyt_support?

    documents = Document.includes(:standard_document, :uploader)
      .where.not(standard_document_id: nil)
      .order(created_at: :desc, updated_at: :desc)
      .page(@page).per(@per_page)

    @pages_count = documents.total_pages

    documents
  end

  def get_documents_by_standard_folder
    Api::Web::V1::StandardFoldersQuery
      .new(@current_advisor, @params).get_category_documents
  end

  def get_documents_for_object
    object = get_object(@params)
    return Document.none unless object # return empty relation if we can't find client/group_user

    get_documents_by_standard_folder #If standard_folder is nil, then it will return the documents that are not assigned to any standard_folder yet
  end
end
