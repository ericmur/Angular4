class Api::DocytBot::V1::Filters::OwnerFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
  end

  def call
    Rails.logger.debug "[DocytBot] Processing filter: OwnerFilter"
    g_users = get_contacts_by_relationship
    if g_users.first
      Rails.logger.debug "[DocytBot] Detected contacts. Names: #{g_users.map(&:name)}, IDs: #{g_users.map(&:id)} by relationship"
      @ctx[:document_ids] = get_docs_ids_for_contacts(g_users)
    elsif (g_users = get_contacts_by_name).first
      Rails.logger.debug "[DocytBot] Detected contacts. Name: #{g_users.map(&:name)}, IDs: #{g_users.map(&:id)} by name"
      @ctx[:document_ids] = get_docs_ids_for_contacts(g_users)
    else
      if is_it_myself?
        Rails.logger.debug "[DocytBot] Detected user himself."
        @ctx[:document_ids] = get_docs_ids_for_user
      else
        Rails.logger.debug "[DocytBot] No user specified. Choosing user himself"
        @ctx[:document_ids] = get_docs_ids_for_user
      end
    end

    Rails.logger.debug "[DocytBot] Document Ids with Owner Filter: #{@ctx[:document_ids].inspect}"
    return @ctx
  end

  private
  def is_it_myself?
    if @user.name and ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(@user.name).to_i == 1
      true
    elsif @user.first_name and ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(@user.first_name).to_i == 1
      true
    elsif @user.first_name and ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(@user.last_name).to_i == 1
      true
    else
      false
    end
  end
  
  def get_contacts_by_relationship
    labels = GroupUser::LABELS.select { |guser_label|
      ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(guser_label).to_i == 1 or ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(guser_label + "s").to_i == 1
    }
    @user.group_users_as_group_owner.select { |gu|
      labels.find { |label|
        gu.has_personal_relationship?(label)
      }
    }
  end

  def get_contacts_by_name
    us = @user.group_users_as_group_owner
    c = us.select { |g_user|
      if g_user.name and (::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.name).to_i == 1 or ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.name + "s").to_i == 1)
        true
      else
        false
      end
    }
    if c.empty?
      c = us.select { |g_user|
        if g_user.first_name and (::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.first_name).to_i == 1 or ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.first_name + "s").to_i == 1)
          true
        else
          false
        end
      }

      if c.empty?
        c = us.select { |g_user|
          if g_user.last_name and (::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.last_name).to_i == 1 or ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(g_user.last_name + "s").to_i == 1)
            true
          else
            false
          end
        }
      else
        c
      end
    else
      c
    end
  end

  def get_docs_ids_for_contacts(g_users)
    docs_ids = []
    g_users.each do |g_user|
      u = g_user.user_id ? g_user.user : g_user
      u_docs_ids = u.document_ownerships.joins(:document).where("documents.standard_document_id is not null").pluck(:document_id)
      docs_ids += SymmetricKey.where(:document_id => u_docs_ids).for_user_access(@user.id).pluck(:document_id)
      if g_user.user and is_business_account?(g_user.user)
        business_document_ids = BusinessDocument.where(:business_id => g_user.user.businesses.pluck(:id)).pluck(:document_id)
        biz_document_ids = SymmetricKey.where(:document_id => business_document_ids).for_user_access(g_user.user_id).pluck(:document_id)
        docs_ids += biz_document_ids
      end
    end
    docs_ids.uniq
  end

  def get_docs_ids_for_user
    docs_ids = @user.document_ownerships.joins(:document).where("documents.standard_document_id is not null").pluck(:document_id)

    if is_business_account?(@user)
      business_document_ids = BusinessDocument.where(:business_id => @user.businesses.pluck(:id)).pluck(:document_id)
      biz_docs_ids = SymmetricKey.where(:document_id => business_document_ids).for_user_access(@user.id).pluck(:document_id)
      (docs_ids + biz_docs_ids).uniq
    else
      docs_ids
    end
  end

  def is_business_account?(u)
    if u.consumer_account_type_id == ConsumerAccountType::BUSINESS
      return true
    else
      return false
    end
  end
end
