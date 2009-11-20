require 'submission'
require 'spec'
require 'rack/test'
require 'digest/md5'
require 'pp'

set :environment, :test

describe "Submission Service" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before(:each) do
    header "X_PACKAGE_NAME", "ateam"
    header "CONTENT_MD5", "901890a8e9c8cf6d5a1a542b229febff"
    header "X_ARCHIVE_TYPE", "zip"
  end

  it "returns 405 on GET" do
    get '/'

    last_response.status.should == 405
  end

  it "returns 405 on DELETE" do
    delete '/'

    last_response.status.should == 405
  end

  it "returns 405 on HEAD" do
    head '/'

    last_response.status.should == 405
  end

  it "returns 400 on POST if request is missing X-Package-Name header" do
    header "X_PACKAGE_NAME", nil

    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_PACKAGE_NAME" 
  end

  it "returns 400 on POST if request is missing Content-MD5 header" do
    header "CONTENT_MD5", nil

    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: CONTENT_MD5" 
  end

  it "returns 400 on POST if request is missing X_ARCHIVE_TYPE header" do
    header "X_ARCHIVE_TYPE", nil

    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_ARCHIVE_TYPE" 
  end


  it "returns 400 on POST if X_ARCHIVE_TYPE is a value different from 'tar' or 'zip'" do
    header "X_ARCHIVE_TYPE", "foo"

    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "X_ARCHIVE_TYPE header must be either 'tar' or 'zip'" 
  end

  it "returns 400 on POST if there is no body" do
    post "/"

    last_response.status.should == 400
    last_response.body.should == "Missing body" 
  end

  it "returns 412 on POST if md5 checksum of body does not match md5 query parameter" do
    header "CONTENT_MD5", "cccccccccccccccccccccccccccccccc"

    post "/", "FOO"

    last_response.status.should == 412
    last_response.body.should == "MD5 of body does not match provided CONTENT_MD5" 
  end

  it "should return 500 if there is an unexpected exception" do
    Digest::MD5.stub!(:new).and_raise(StandardError)
    
    post "/", "FOO"
    last_response.status.should == 500

  end

  it "should return 400 if submitted package is not a zip file when request header says it should be" do
    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Error extracting files in request body, is it malformed?" 
  end

  it "should return 400 if submitted package is not a tar file when request header says it should be" do
    header "X_ARCHIVE_TYPE", "tar"

    post "/", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Error extracting files in request body, is it malformed?" 
  end

  #it "should return 200 on valid post request" do
    #post "/", "FOO"
#
    #last_response.status.should == 200
  #end
end
