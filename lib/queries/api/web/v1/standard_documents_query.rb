class Api::Web::V1::StandardDocumentsQuery
  PER_PAGE = 20

  def initialize(current_advisor, params)
    @page      = params[:page]
    @params    = params
    @per_page  = params[:per_page] || PER_PAGE

    @for_support     = params[:for_support]
    @business_id     = params[:business_id]
    @for_client_id   = params[:for_client_id]
    @current_advisor = current_advisor
  end

  def set_base_documents
    if @for_support
      @standard_documents = get_for_support
    else
      get_document_types
    end
  end

  def pages_count
    @standard_documents.total_pages if @standard_documents.respond_to?(:total_pages)
  end

  def get_document_types
    client = get_client(@params[:client_id], @params[:client_type])

    if client
      query_params = get_query_params_for_user_document_types(client)
    else
      query_params = { user_id: @current_advisor.id, user_type: @current_advisor.class.to_s }
    end

    system_document_types = StandardDocument.where(
      consumer_id: nil
    )

    user_document_types = StandardDocument.joins(:owners)
      .where("standard_base_document_owners.owner_id = ? and standard_base_document_owners.owner_type = ?",
              query_params[:user_id], query_params[:user_type])

    # returns a relation, uses SQL's UNION method
    system_document_types.union(user_document_types)
    .select(
        'standard_base_documents.id AS id,
        standard_base_documents.name AS name, (
          SELECT
            standard_folder_standard_documents.standard_folder_id
          FROM
            standard_folder_standard_documents
          WHERE
            standard_folder_standard_documents.standard_base_document_id = standard_base_documents.id
          GROUP BY
            standard_folder_standard_documents.id
          LIMIT 1
        ) AS standard_folder_id, (
          SELECT
            standard_folders.name
          FROM
            standard_folder_standard_documents,
            standard_base_documents standard_folders
          WHERE
            standard_folders.type in(\'StandardFolder\')
            AND
            standard_folders.id = standard_folder_standard_documents.standard_folder_id
            AND
            standard_folder_standard_documents.standard_base_document_id = standard_base_documents.id
          GROUP BY
            standard_folders.name
          LIMIT 1
        ) AS category_name')
      .group('standard_base_documents.id, standard_base_documents.name')
  end

  def get_document_types_for_docyt_support
    return unless @current_advisor.docyt_support?

    StandardDocument.select("standard_base_documents.*, count(documents.id) AS doc_count")
      .joins("LEFT OUTER JOIN documents on documents.standard_document_id = standard_base_documents.id")
      .group("standard_base_documents.id")
      .order("doc_count DESC")
      .page(@page)
      .per(@per_page)
  end

  def get_client_document_types_for_docyt_support
    client = Client.find_by(id: @for_client_id)

    return unless client && @current_advisor.docyt_support?

    StandardDocument.joins(:documents)
      .where(documents: { consumer_id: client.consumer_id })
      .select('standard_base_documents.*, count(documents.id) AS doc_count')
      .group("standard_base_documents.id")
      .order("doc_count DESC")
  end

  def get_for_support
    return get_client_document_types_for_docyt_support if @for_client_id

    get_document_types_for_docyt_support
  end

  private

  def get_client(client_id, client_type)
    if client_type == Client.name.to_s
      @current_advisor.clients_as_advisor.find_by(id: client_id)
    elsif client_type == GroupUser.name.to_s
      consumer_id = GroupUser.find_by(id: client_id).group.owner.id
      @current_advisor.clients_as_advisor.find_by(consumer_id: consumer_id)
    end
  end

  def get_query_params_for_user_document_types(client)
    {
      user_id:   client.consumer_id ? client.consumer_id : client.id,
      user_type: client.consumer_id ? 'User' : 'Client'
    }
  end

end
