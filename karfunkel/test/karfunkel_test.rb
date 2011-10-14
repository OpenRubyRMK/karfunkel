# -*- coding: utf-8 -*-
gem "test-unit"

require "pathname"
require "erb"
require "socket"

require "test/unit"
require_relative "../lib/open_ruby_rmk/karfunkel/server_management/karfunkel"

#Base class for tests regarding OpenRubyRMK’s server. It can simulate requests,
#responses and notifications and provdides you with what Karfunkel answers to this.
class KarfunkelTest < Test::Unit::TestCase

  TEST_DATA_DIR      = Pathname.new(__FILE__).dirname.expand_path + "data"
  TEST_REQUESTS_DIR  = TEST_DATA_DIR + "requests"
  TEST_RESPONSES_DIR = TEST_DATA_DIR + "responses"
  KARFUNKEL_DOMAIN   = "localhost"
  KARFUNKEL_PORT     = 3141
  COMMAND_SEPARATOR  = "\0"

  #On first test execution, start up Karfunkel and run him in the background.
  def self.startup
    @karfunkel_pid = spawn(
                           "#{OpenRubyRMK::Karfunkel::Paths::ROOT_DIR.join("bin", "karfunkel")} -d", 
                           out: TEST_DATA_DIR.join("karfunkel.log").to_s, 
                           err: :out)
    sleep 5 #Wait for Karfunkel to be ready
    @socket = TCPSocket.new(KARFUNKEL_DOMAIN, KARFUNKEL_PORT)

    #Greet Karfunkel and establish the connection
    request("Hello", :os => "Unknown")
    cmd = OpenRubyRMK::Karfunkel::SM::Command.from_xml(@socket.read("\0"), nil)
    raise("Can't greet Karfunkel!") unless cmd.responses.first.type == "Ok"
    @client_id = cmd["id"]

    @requests      = []
    @responses     = []
    @notifications = []
    @conn_mutex  = Mutex.new #Only ONE may write to the socket
    @conn_thread = Thread.new do
      while(data = @socket.read("\0"))
        command = OpenRubyRMK::Karfunkel::SM::Command.from_xml(str, nil)
        
        command.requests.each do |req|
          if req.type == "Ping"
            response("Pong") #Automatically answer PING requests
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

  #Sends a request with the given parameters to Karfunkel. Requests are looked
  #for in the data/requests directory.
  def request(name, parameters = {})
    path = TEST_REQUESTS_DIR + "#{name}.xml"
    raise(ArgumentError, "Request file for #{name} not found!") unless path.file?
    
    xml = ERB.new(path.read).result(binding)
    answer(xml)
    sleep 0.5 #Time to allow an answer
  end

  #Sends a response with the given parameters to Karfunkel. Responses are looked for
  #in the data/responses directory.
  def response(name, parameters = {})
    path = TEST_RESPONSES_DIR + "#{name}.xml"
    raise(ArgumentError, "Response file for #{name} not found!") unless path.file?

    xml = ERB.new(path.read).result(binding)
    answer(xml)
  end

  #Sends a notification with the given parameters to Karfunkel. Notifications are
  #looked for in the data/notifications directory. As the tests are clients, sending
  #notifications to Karfunkel is merely nonsense.
  def notification(name, parameters = {})
    path = TEST_NOTES_DIR + "#{name}.xml"
    raise(ArgumentError, "Notification file for #{name} not found!") unless path.file?

    xml = ERB.new(path.read).result(binding)
    answer(xml)
  end
  
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
