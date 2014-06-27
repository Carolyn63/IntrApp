# Paperclip.options[:command_path] = "/usr/local/bin"
unless PLATFORM =~ /win32/i
  begin
    if `ls /usr/local/bin`.match /identify/
      Paperclip.options[:command_path] = "/usr/local/bin"
    elsif `ls /usr/bin`.match /identify/
      Paperclip.options[:command_path] = "/usr/bin"
    else
      puts "\nMisconfigured ImageMagick or Windows\n"
    end
  rescue => e
  end
end
Paperclip.options[:whiny_thumbnails] = true
Paperclip.options[:log] = true

