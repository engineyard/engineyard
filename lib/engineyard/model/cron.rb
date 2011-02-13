module EY
  module Model
    class Cron < ApiStruct.new(:id, :name, :command, :weekday, :month, :day, :hour, :minute, :user)

      def crontab
        "#{minute}\t#{hour}\t#{day}\t#{month}\t#{weekday}\t#{command}"
      end
      
      def self.header
        <<-HEADER.gsub(/^\s{8}/, '')
        # Minute   Hour   Day of Month       Month          Day of Week        Command
        # (0-59)  (0-23)     (1-31)    (1-12 or Jan-Dec)  (0-6 or Sun-Sat)                
        HEADER
      end
    end
  end
end
