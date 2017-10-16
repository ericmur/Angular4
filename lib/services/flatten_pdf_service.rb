require 'fileutils'
require 'open3'

class FlattenPdfService
  def initialize(path)
    @path = path
    @temp_folder_location = generate_temp_folder_path('flattened_pdf')
    @pdf_filename = File.basename(path)
    @temp_pdf_location = "#{@temp_folder_location}#{@pdf_filename}"
  end

  def fillable?
    cmd = "pdfinfo \"#{@path}\""
    stdout, stdeerr, status = Open3.capture3(cmd) # Use capture3 instead of using `system` or `backticks`
    if status.exitstatus == 0
      return stdout.gsub(' ','').split("\n").reject(&:blank?).select{|s|s.match(/Form:none/)}.blank?
    end
    raise stdeerr.split("\n").first.strip
  end

  def flatten
    FileUtils.mkdir_p(@temp_folder_location)

    check_for_protected_pdf

    cmd = "pdf2ps \"#{@path}\" - | ps2pdf - \"#{@temp_pdf_location}\""
    stdout, stdeerr, status = Open3.capture3(cmd) # Use capture3 instead of using `system` or `backticks`
    unless status.exitstatus == 0
      if stdeerr.present?
        raise stdeerr.split("\n").first.strip
      elsif stdout.present?
        raise stdout.split("\n").first.strip
      else
        raise "Flattening of pdf failed for: #{@path}, cmd: #{cmd}"
      end
    end

    FileUtils.mv(@temp_pdf_location, @path)
  ensure
    FileUtils.remove_dir(@temp_folder_location)
  end

  private

  def check_for_protected_pdf
    cmd = "pdf2ps \"#{@path}\""
    stdout, stdeerr, status = Open3.capture3(cmd)
    unless status.exitstatus == 0
      if stdout.present?
        raise stdout.split("\n").first.strip
      elsif stdeerr.present?
        raise stdeerr.split("\n").first.strip
      else
        raise "Flattening of pdf failed for: #{@path}, cmd: #{cmd}"
      end
    end
  end

  def generate_temp_folder_path(folder_name)
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    "./tmp/#{folder_name}/#{timestamp}/"
  end
end
