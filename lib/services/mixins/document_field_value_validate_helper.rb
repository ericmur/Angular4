require "date"

module Mixins::DocumentFieldValueValidateHelper
  def check_value_data_type(value, data_type)
    case data_type
      when 'int'
        is_int? value
      when 'float'
        is_float? value
      when 'date'
        is_date? value
      when 'expiry_date'
        is_date? value
      when 'due_date'
        is_date? value
      when 'year'
        (1900..2100).cover? value.to_i
      when 'zip'
        is_us_zip_code? value
      when 'text'
        value.is_a? String
      when 'string'
        value.is_a? String
      when 'boolean'
        return true if value.to_i == 1 || value.to_i == 0
        false
      when 'url'
        is_valid_url? value
      when 'currency'
        is_currency? value
      when 'country'
        value.is_a? String
      when 'state'
        value.is_a? String
      when 'phone'
        is_us_phone_number? value
      else
        false
    end
  end

  def is_date?(obj)
    obj.to_s.match(/\A(0?[1-9]|1[012])\/(0?[1-9]|[12][0-9]|3[01])\/\d{4}\Z/) == nil ? false : true
  end

  def is_int?(obj)
    obj.to_s.match(/\A\d+?(\s?\d+)+\Z/) == nil ? false : true
  end

  def is_float?(obj)
    obj.to_s.match(/\A\d+?((,|\s)?\d+)+\Z/) == nil ? false : true
  end

  def is_currency?(obj)
    obj.to_s.match(/\A(?=\(.*\)|[^()]*$)\(?\d{1,3}(,?\d{3})?(\.\d\d?)?\)?\Z/) == nil ? false : true
  end

  def is_us_phone_number?(obj)
    obj.to_s.match(/\A(\([0-9]{3}\)|[0-9]{3}-)\s?[0-9]{3}-[0-9]{4}\Z/) == nil ? false : true
  end

  def is_us_zip_code?(obj)
    obj.to_s.match(/\A\d{5}(?:[-\s]\d{4})?\Z/) == nil ? false : true
  end

  def is_valid_url?(obj)
    obj.to_s.match(/\A((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)\Z/) == nil ? false : true
  end
end
