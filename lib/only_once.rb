
class OnlyOnce
  class << self
    attr_accessor :db_file
    
    def use_path=(path)
      self.db_file = path + '/only_once.db'
      File.open(@db_file, 'a+')
    end
    
    def get_a_context
      self.new(caller[1])
    end
    
    def with_context(context)
      new(context)
    end
    
    def in(seconds, &bl)
      get_a_context.in(seconds, &bl)
    end
    
    def update_db(key, val)
      formatted_val = '%10s' % val.to_s
      File.open(@db_file, 'a+') do |io|
        io.flock(File::LOCK_EX)
        io.rewind
        io.puts key if !search_db(io,key)
        io.puts formatted_val
      end
    end
    
    def lookup_db(key)
      retval = nil
      File.open(@db_file, 'r') do |io|
        io.flock(File::LOCK_SH)
        retval = io.readline.strip if search_db(io,key)
      end
      retval
    end
    
    protected
    def search_db(io, key)
      retval = nil
      keywithnewline = "#{key}\n"
      while(retval.nil? && line = io.gets)
        if(line == keywithnewline)
          retval = true 
        else
          io.gets  # skip over the next value
        end
      end
      retval
    end
  end
  
  @db_file = File.dirname(__FILE__) + '/only_once.db'
  
  def initialize(context)
    @context = context
  end
  
  def in(seconds)
    if(!last_happened || last_happened && (Time.now.to_i > (last_happened + seconds.to_i)))
      update_last_happened
      yield
    end
  end
  
  def last_happened
    @last_happened ||= (self.class.lookup_db(@context).to_i rescue nil)
  end
  
  def update_last_happened
    self.class.update_db(@context, Time.now.to_i)
  end
  
end
