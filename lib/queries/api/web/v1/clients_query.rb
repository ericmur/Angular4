class Api::Web::V1::ClientsQuery
  CLIENTS_PER_PAGE = 20

  def initialize(current_advisor, params)
    @page = params[:page] || 1

    @search_data = params[:search_data]
    @sort_method = setup_sort_method(params[:sort_method])

    @only_connected   = params[:only_connected]
    @current_advisor  = current_advisor
    @fulltext_search  = params[:fulltext_search]
    @clients_per_page = params[:per_page] || CLIENTS_PER_PAGE
  end

  def get_clients
    return get_connected_clients if @only_connected

    if @sort_method == 'sort_by_count_of_unread_messages'
      @clients = sort_by_unread_messages
    else
      @clients = @current_advisor.clients_as_advisor.order(@sort_method).page(@page).per(@clients_per_page)
    end
  end

  def get_total_pages
    @clients.total_pages if @clients.respond_to?(:total_pages)
  end

  def search_clients
    @scope = get_default_scope

    @scope = search_users(@search_data) if @search_data
    @scope = fulltext_clients_search(@fulltext_search) if @fulltext_search

    @scope
  end

  def sort_by_unread_messages
    @current_advisor.clients_as_advisor.joins("
      LEFT JOIN
        users
      ON
        users.id = clients.consumer_id
      LEFT JOIN
        messages
      ON
        users.id = messages.sender_id
      LEFT JOIN
        message_users
      ON
        messages.id = message_users.message_id"
    ).where("message_users.read_at IS NULL")
    .select('clients.*','COUNT (message_users.id) AS mes_users_count')
    .group('clients.id')
    .order('mes_users_count DESC').page(@page).per(CLIENTS_PER_PAGE)
  end

  private

  def setup_sort_method(sort_method)
    case sort_method
    when 'Newest'
      'created_at DESC'
    when 'Oldest'
      'created_at ASC'
    when 'Unread Messages Count'
      'sort_by_count_of_unread_messages'
    else
      'created_at DESC'
    end
  end

  def get_default_scope
    @current_advisor.clients_as_advisor.joins(
      "LEFT JOIN
        users
      ON
        clients.consumer_id = users.id"
    )
  end

  def search_users(phrase)
    @scope.where(
     'users.first_name ILIKE :search
      OR users.last_name ILIKE :search
      OR users.email ILIKE :search', search: "%#{phrase}%"
    )
  end

  def fulltext_clients_search(phrase)
    @scope.where(
     'users.first_name ILIKE :search
      OR users.last_name ILIKE :search
      OR users.email ILIKE :search
      OR users.phone_normalized ILIKE :search
      OR clients.name ILIKE :search
      OR clients.email ILIKE :search
      OR clients.phone_normalized ILIKE :search', search: "%#{phrase}%"
    )
  end

  def get_connected_clients
    @clients = @current_advisor.clients_as_advisor.joins(:consumer)
  end

end
