require 'rails_helper'

RSpec.describe GoogleDriveRefreshTokenRetrieverJob, type: :job do
  it "should create a cloud_service_auth for a new cloud service account"
  
  it "should proceed by not updating token if Google reports that an already redeemed auth_code was used"

  it "should update a valid token in existing cloud_service_auth model if it already exists for that Drive account"

  it "should throw an error and not update the token in an existing cloud_service_auth model if token could not be retrieved due to invalid auth_code" 

  it "should throw an error and not create a new auth_code if token could not be retrieved due to invalid auth_code"

  it "should not create a path if token could not be retrieved due to invalid code" 

  it "should create a path even if token was already redeemed and call sync_data was called on it"

  it "should create a path for valid token and call sync_data on it"

  it "should use the existing path if one exists and call sync_data on it"
end
