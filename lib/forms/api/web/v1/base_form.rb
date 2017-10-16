class Api::Web::V1::BaseForm < Rectify::Form

  def save
    if valid?
      persist!
      true
    else
      false
    end
  end

  private

  def persist!
    raise "Implement in the subclass"
  end

end