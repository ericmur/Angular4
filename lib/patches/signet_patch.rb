# Patch for Signet bug with timestamps on 32-bit systems
# https://github.com/google/signet/issues/70
module Signet
  module OAuth2
    class Client
      alias_method :o_normalize_timestamp, :normalize_timestamp
      def normalize_timestamp(time)
        case time
        when NilClass
          nil
        when Time
          time
        when String
          Time.parse(time)
        when Fixnum, Bignum
          #Adding Bignum ^ here as timestamps like 1453983084 are bignums on 32-bit systems
          Time.at(time)
        else
          fail "Invalid time value #{time}"
        end
      end
    end
  end
end
