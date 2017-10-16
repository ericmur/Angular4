require "rails_helper"

RSpec.describe Mixins::DocumentFieldValueValidateHelper do
  let(:helper) { Class.new { extend Mixins::DocumentFieldValueValidateHelper } } 

  describe "#is_valid_url?" do
    context "with invalid value" do
      it "with uncorrect url" do
        result = helper.is_valid_url?("url")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "with full address" do
        result = helper.is_valid_url?("http://url.com")

        expect(result).to be true
      end

      it "with semi full address" do
        result = helper.is_valid_url?("www.url.com")
        
        expect(result).to be true
      end

      it "with query string" do
        result = helper.is_valid_url?("www.url-with-querystring.com/?url=has-querystring")
        
        expect(result).to be true
      end
    end
  end

  describe "#is_currency?" do
    context "with invalid value" do
      it "with 6 position with double space" do
        result = helper.is_currency?("111  111")

        expect(result).to be false
      end

      it "with 6 position with out comma" do
        result = helper.is_currency?("111 111")

        expect(result).to be false
      end

      it "with 0 position and 2 position after comma" do
        result = helper.is_currency?(".11")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "with 6 position and 2 position after comma" do
        result = helper.is_currency?("111,111.11")

        expect(result).to be true
      end

      it "with 2 position with out comma" do
        result = helper.is_currency?("11")

        expect(result).to be true
      end

      it "with 2 position and 2 position after comma" do
        result = helper.is_currency?("11.11")

        expect(result).to be true
      end

      it "with 1 position and 2 position after comma" do
        result = helper.is_currency?("1.11")

        expect(result).to be true
      end
    end
  end

  describe "#is_us_zip_code?" do
    context "with invalid value" do
      it "with wrong zip code" do
        result = helper.is_us_zip_code?("11111-111")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "zip with - between numbers" do
        result = helper.is_us_zip_code?("11111-1111")

        expect(result).to be true
      end

      it "with valid value zip with space between numbers" do
        result = helper.is_us_zip_code?("11111 1111")

        expect(result).to be true
      end
    end
  end

  describe "#is_us_phone_number?" do
    context "with invalid value" do
      it "if uncorrect phone number with space" do
        result = helper.is_us_phone_number?("(111) 111-111")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "if correct phone number with space" do
        result = helper.is_us_phone_number?("(111) 111-1111")

        expect(result).to be true
      end

      it "if correct phone number without space" do
        result = helper.is_us_phone_number?("(111)111-1111")

        expect(result).to be true
      end
    end
  end

  describe "#is_float?" do
    context "with invalid value" do
      it "with 6 position with double space" do
        result = helper.is_float?("111  111")

        expect(result).to be false
      end

      it "with 6 position with comma" do
        result = helper.is_float?("111.111")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "with 6 position with out comma" do
        result = helper.is_float?("111 111")

        expect(result).to be true
      end

      it "with 6 position and 2 position after comma" do
        result = helper.is_float?("111 111,11")

        expect(result).to be true
      end

      it "with 2 position with out comma" do
        result = helper.is_float?("11")

        expect(result).to be true
      end

      it "with 2 position and 2 position after comma" do
        result = helper.is_float?("11,11")

        expect(result).to be true
      end
    end
  end

  describe "#is_int?" do
    context "with invalid value" do
      it "with 6 position and 2 decimals" do
        result = helper.is_int?("111 111,11")

        expect(result).to be false
      end

      it "with 6 position and comma" do
        result = helper.is_int?("111.111")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "with 6 position" do
        result = helper.is_int?("111 111")

        expect(result).to be true
      end

      it "with 2 position" do
        result = helper.is_int?("11")

        expect(result).to be true
      end
    end
  end

  describe "#is_date?" do
    context "with invalid value" do
      it "with wrong month" do
        result = helper.is_date?("13/23/2016")

        expect(result).to be false
      end

      it "with wrong day" do
        result = helper.is_date?("13/32/2016")

        expect(result).to be false
      end
    end

    context "with valid value" do
      it "with correct date" do
        result = helper.is_date?("08/20/2016")

        expect(result).to be true
      end
    end
  end

  describe "#check_value_data_type" do
    context "with valid value" do
      it "validating int data_type" do
        value     = "222 222"
        data_type = "int"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating float data_type" do
        value     = "222 222,22"
        data_type = "float"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating date data_type" do
        value     = "08/01/2016"
        data_type = "date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating expiry_date data_type" do
        value     = "08/01/2016"
        data_type = "expiry_date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating due_date data_type" do
        value     = "08/01/2016"
        data_type = "due_date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating year data_type" do
        value     = "2016"
        data_type = "year"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating zip data_type" do
        value     = "20162-2222"
        data_type = "zip"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating text data_type" do
        value     = "Some long text for validating"
        data_type = "text"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating string data_type" do
        value     = "Some string for validating"
        data_type = "string"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating boolean data_type" do
        value     = "1"
        data_type = "boolean"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating url data_type" do
        value     = "www.url.com"
        data_type = "url"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating currency data_type" do
        value     = "232,233.22"
        data_type = "currency"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating country data_type" do
        value     = "USA"
        data_type = "country"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating state data_type" do
        value     = "California"
        data_type = "state"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end

      it "validating phone data_type" do
        value     = "(111) 111-1111"
        data_type = "phone"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be true
      end
    end

    context "with invalid value" do
      it "validating int data_type" do
        value     = "222.222gw"
        data_type = "int"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating float data_type" do
        value     = "222.222,22gw"
        data_type = "float"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating date data_type" do
        value     = "13/23/2016"
        data_type = "date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating expiry_date data_type" do
        value     = "13/23/2016"
        data_type = "expiry_date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating due_date data_type" do
        value     = "13/23/2016"
        data_type = "due_date"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating year data_type" do
        value     = "2216"
        data_type = "year"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating zip data_type" do
        value     = "20162-22"
        data_type = "zip"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating boolean data_type" do
        value     = "2"
        data_type = "boolean"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating url data_type" do
        value     = "url"
        data_type = "url"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating currency data_type" do
        value     = "232.233,22dd"
        data_type = "currency"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end

      it "validating phone data_type" do
        value     = "(111) 111-"
        data_type = "phone"

        result = helper.check_value_data_type(value, data_type)

        expect(result).to be false
      end
    end
  end
end
