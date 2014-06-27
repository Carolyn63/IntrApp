module Tools
  class ApiLogger

    def initialize options = {}
      @name = options[:name]
      @need_filter = options[:need_filter] || false
      @filters_field = options[:filters] || ["password", "crypted_password", "password_confirmation", "pwd"]
    end
    
    def exists?
      File.exist? log_file_name
    end

    def log_file_name
      @file_name ||= log_file_dir + "/#{@name}.log"
      @file_name
    end
    
    def log_file_size
      begin
        File.size( log_file_name )
      rescue => e
        0
      end
    end
    

    def log_file_dir
      @file_dir ||= RAILS_ROOT + "/log"
      @file_dir
    end
    
    def log_data 
      file = File.open( log_file_name )
      data = CGI.escapeHTML( file.read )
      file.close
      data
    end

    def start_logging
      unless File.exist?(log_file_dir)
        Dir.mkdir log_file_dir
      end
      @log_file = File.open( log_file_name, "a+" )
    end
    
    def stop_logging
      @log_file.close
    end
    
    
    def put( data )
      @log_file << "#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}: " + data + "\n"
    end
    

  end
  
end
