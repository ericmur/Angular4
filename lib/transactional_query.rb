module TransactionalQuery
  def transactional_save(&block)
    ActiveRecord::Base.transaction(requires_new: true) do 
      begin
        yield
        self.save!
      rescue Exception => e
        self.errors[:base] << "Error: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    if self.errors.empty?
      return true
    else
      return false
    end
  end

  def transactional_execute(&bock)
    ActiveRecord::Base.transaction(requires_new: true) do 
      begin
        yield
      rescue Exception => e
        self.errors[:base] << "Error: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    if self.errors.empty?
      return true
    else
      return false
    end
  end

  def transactional_destroy(&block)
    ActiveRecord::Base.transaction(requires_new: true) do 
      begin
        yield
        self.destroy
      rescue Exception => e
        self.errors[:base] << "Error: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    if self.errors.empty?
      return true
    else
      return false
    end
  end
end
