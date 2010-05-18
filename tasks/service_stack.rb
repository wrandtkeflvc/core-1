require 'rack'
require 'aip'
require 'db/operations_agents'
require 'db/operations_events'

VAR_DIR = File.join File.dirname(__FILE__), '..', 'var'
SERVICES_DIR = File.join VAR_DIR, 'services'
SILO_DIR = File.join VAR_DIR, 'silo'

REPOS = {
  'describe' => 'git://github.com/daitss/describe.git',
  'storage' => 'git://github.com/daitss/storage.git',
  'actionplan' => 'git://github.com/daitss/actionplan.git',
  'viruscheck' => 'git://github.com/daitss/viruscheck.git',
  'transform' => 'git://github.com/daitss/transform.git',
  'submission' => 'git://github.com/daitss/submission.git',
  'request' => 'git://github.com/daitss/request.git'
}

def check_clamscan

  unless %x{clamscan --version 2>&1}.lines.first =~ /ClamAV/
    raise "clamscan not found"
  end

end

def check_ffmpeg

  unless %x{ffmpeg -version 2>&1}.lines.first =~ /FFmpeg version /
    raise "ffmpeg not found"
  end

end

def check_ghostscript

  unless %x{gs -version}.lines.first =~ /Ghostscript [\d.]+/
    raise "ghostscript not found"
  end

end

def require_services


  %w(describe viruscheck actionplan transform storage submission request).each do |service|
    service_dir = File.join SERVICES_DIR, service
    $:.unshift File.join(service_dir, 'lib')

    app_filename = case service
                   when 'describe' then 'describe'
                   when 'transform' then 'transform'
                   when 'submission' then 'submission'
                   when 'request' then 'hermes'
                   else 'app'
                   end

    require File.join(service_dir, app_filename)
  end

  $:.unshift File.join File.dirname(__FILE__), '..', 'lib'
  require 'statusecho'

end

def service_stack
  check_ghostscript
  check_ffmpeg
  require_services

  Rack::Builder.new do
    use Rack::CommonLogger
    use Rack::ShowExceptions
    use Rack::Lint

    map "/description" do
      run Describe.new
    end

    map "/viruscheck" do
      run VirusCheckService::App.new
    end

    map "/actionplan" do
      run ActionPlan::App.new
    end

    map "/transformation" do
      run Transform.new
    end

    map "/silo" do
      run SimpleStorage::App.new(SILO_DIR)
    end

    map "/submission" do
      run Submission::App.new
    end

    map "/request" do
      run Hermes::App.new
    end

    map "/statusecho" do
      run StatusEcho.new
    end

  end

end

namespace :services do

  desc "fetch the services"
  task :fetch do

    FileUtils::mkdir_p SERVICES_DIR


    Dir.chdir SERVICES_DIR do

      REPOS.each do |name, url|

        if File.exist? name
          puts "updating:\t#{name}"
          Dir.chdir(name) { %x{git pull} }
          raise "error updating #{name}" unless $? == 0
        else
          puts "fetching:\t#{name}"
          %x{git clone #{url} #{name}}
          raise "error fetching #{name}" unless $? == 0
        end

      end

    end

  end

  desc "nuke the services dir"
  task :clobber do
    FileUtils::rm_rf SERVICES_DIR
    FileUtils::mkdir SERVICES_DIR
  end

  desc "run the service stack"
  task :run do

    # make the silo sandbox
    FileUtils::rm_rf SILO_DIR
    FileUtils::mkdir_p SILO_DIR

    # make the database sandbox
    DataMapper.setup :default, Daitss::CONFIG['database-url']

    # run the test stack
    httpd = Rack::Handler::Thin
    httpd.run service_stack, :Port => 7000
  end

end
