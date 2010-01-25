require 'tempdir'
require 'aip'
require 'wip'
require 'representation'
require 'service/validate'
require 'service/describe'
require 'service/actionplan'
require 'service/transform'
require 'descriptor'
require 'template/premis'

class Wip

  def ingest!
    
    begin
      step('validate') { validate! }
      datafiles.each { |df| step("describe-#{df.id}") { df.describe! } }

      # determine existing original_rep and current_rep
      step('set-original-representation') { self.original_rep = datafiles if original_rep.empty? }
      step('set-current-representation') { self.current_rep = original_rep if current_rep.empty? }

      # new reps
      new_current_rep = current_rep.map do |df| 

          # pass description to actionplan/migrations
          transformation_url = df.migration

          if transformation_url

            # transform into a new datafile either give a new datafile or cleanup any mess
            new_df = step("migrate-#{df.id}") { transform df.datapath, transformation_url } 

            # describe it
            step("describe-#{new_df.id}") { new_df.describe! :derivation => df } 

            new_df
          else
            df
          end


      end

      # new_current_rep = current_rep.map { |df| df.migrate || df } 
      #new_normalized_rep = original_rep.map { |df| df.normalize || df }

      # persist the representations
      step('update-current-representation') { self.current_rep = new_current_rep unless new_current_rep == current_rep }
      #step('update-normalized-representation') { self.normalized_rep = new_normalized_rep unless new_normalized_rep == normalized_rep }

      # clean out undescribed files
      represented_files, unrepresented_files = represented_file_partitions
      unrepresented_files.each { |df| step("obsolete-#{df.id}") { df.obsolete! } }

      # TODO import old package level provenance
      # TODO make sure obsolete datafiles have premis objects
      # TODO import old data file level provenance for each data file even obsolete ones

      # write the ingest event
      step('write-ingest-event') do
        metadata['ingest-event'] = event(:id => "#{uri}/event/ingest", 
                                         :type => 'ingest', 
                                         :outcome => 'success', 
                                         :linking_objects => [ uri ])
      end

      make_aip! represented_files
    rescue Reject => e
      tags['REJECT'] = e.message
    rescue => e
      tags['SNAFU'] = ( [e.message] + e.backtrace ).join "\n"
    end

  end

  private

  def step key

    unless tags.has_key? key
      value = yield
      tags[key] = Time.now.xmlschema
      value
    end

  end

  def make_aip! files

    aip = Aip.new
    aip.id = id
    aip.uri = uri
    aip.xml = descriptor.to_s
    aip.needs_work = true
    aip.copy_url = "#{CONFIG['storage-url']}/#{id}"

    Tempdir.new do |dir|

      Dir::chdir(dir.path) do

        #make the stuff
        FileUtils::mkdir aip.id

        files.each do |f|
          sip_path = File.join aip.id, f['sip-path']
          FileUtils::mkdir_p File.dirname(sip_path)
          FileUtils::ln_s f.datapath, sip_path
        end

        #tar it up
        aip.tarball = %x{tar --dereference --create --file -  #{aip.id}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
      end

    end

    unless aip.save 
      aip.errors.each { |e| puts e }
      raise "could not save aip: #{aip.errors.size}"
    end

  end

end
