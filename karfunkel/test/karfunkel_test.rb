# -*- coding: utf-8 -*-
gem "test-unit"

require "pathname"
require "erb"
require "socket"

require "test/unit"
require_relative "../lib/open_ruby_rmk/karfunkel"

#Base class for tests regarding OpenRubyRMK’s server. It can simulate requests,
#responses and notifications and providides you with what Karfunkel answers to this.
class KarfunkelTest < Test::Unit::TestCase

  KARFUNKEL_DOMAIN  = "localhost".freeze
  KARFUNKEL_PORT    = 3141
  COMMAND_SEPARATOR = "\0"

  HELLO =<<-EOF
<Karfunkel>
  <request type="Hello" id="0">
    <os>Unknown</os>
  </request>
</Karfunkel>\0
  EOF

  PONG =<<-EOF
<Karfunkel>
  <sender>
    <id>%i</id>
  </sender>
  <response type="Ping" id="%i">
  </response>
</Karfunkel>\0
  EOF

  #On first test execution, start up Karfunkel and run him in the background.
  def self.startup
    @karfunkel_pid = spawn("#{OpenRubyRMK::Karfunkel::Paths::ROOT_DIR.join("bin", "karfunkel")} -d", 
                           out: TEST_DATA_DIR.join("karfunkel.log").to_s, 
                           err: :out)
    sleep 5 #Wait for Karfunkel to be ready
    @socket = TCPSocket.new(KARFUNKEL_DOMAIN, KARFUNKEL_PORT)

    #Greet Karfunkel and establish the connection
    @socket.write(HELLO)
    cmd = OpenRubyRMK::Karfunkel::Plugins::Core::Command.from_xml(@socket.read("\0"), nil)
    raise("Can't greet Karfunkel!") unless cmd.responses.first.type == "Ok"
    @client_id = cmd.responses.first["id"].to_i

    @requests      = []
    @responses     = []
    @notifications = []
    @conn_mutex    = Mutex.new #Only ONE may write to the socket
    @conn_thread   = Thread.new do
      while(data = @socket.read("\0"))
        command = OpenRubyRMK::Karfunkel::SM::Command.from_xml(str, nil)
        
        command.requests.each do |req|
          if req.type == "Ping"
            @conn_mutex.synchronize{@socket.write(sprintf(PONG, @client_id, req.id.to_i))}
          else
            @requests << req
          end
        end
        @responses     << command.responses
        @notifications << command.notifications
      end #while
    end #Thread.new
  end #startup

  #After the last test execution shut karfunkel down.
  def self.shutdown
    @conn_thread.terminate
    Process.kill("SIGTERM", @karfunkel_pid)
    sleep 3 #Ensure it can terminate normally.
  end

  private

  def 
  
  #Places +xml+ inside the Karfunkel command layout and writes it
  #directly to the connection’s socket.
  def answer(xml)
    str =<<XML
<Karfunkel>
#{xml}
</Karfunkel>
XML
    @conn_mutex.synchronize do
      @socket.write(str + COMMAND_SEPARATOR)
    end
  end
  
end

__END__
