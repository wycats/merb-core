if ENV["TM_RUBY"]

  module Autotest::HtmlConsole
    MAX = 30
    STATUS = {}
    OUT_DUP = STDOUT.dup
    require 'stringio'
    # $stdout = StringIO.new
    # $stderr = StringIO.new

    OUT_DUP.puts <<-HERE
      <html>
        <head>
          <title>AutoTest Results</title>
          <script>document.body.innerHTML = ''</script>
        </head>
        <body>
        
        </body>
      </html>
    HERE

    def self.update(failures = nil)
      STATUS.delete STATUS.keys.sort.last if STATUS.size > MAX
      STATUS.sort.reverse.each do |t,s|
        if s > 0 then
          OUT_DUP.puts "<p style=\"color:red\">#{t}: #{failures.join("<br/>")}</p>"
        else
          OUT_DUP.puts "<p style=\"color:green\">#{t}: #{s}</p>"
        end
      end
      OUT_DUP.flush
    end

    Autotest.add_hook :red do |at|
      STATUS[Time.now] = at.files_to_test.size
      update(at.failures)
    end

    Autotest.add_hook :green do |at|
      STATUS[Time.now] = 0
      update
    end
  end
end