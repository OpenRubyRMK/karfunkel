# -*- coding: utf-8 -*-
require "minitest/unit"
require "eventmachine"
require "paint"
require_relative "../karfunkel"

#A client for Karfunkel specifally designed to test his networking
#facilities. This is a protocol module for use with EventMachine
#and is heavily integrated with the OpenRubyRMK::Karfunkel::TestCase
#class. Inside an instance of TestCase, during the actual testing
#you have access to an instance of an anonymous class mixing in
#this module via TestCase#client. Usually you won’t need that
#instance because the helper methods hide it away from you,
#but it might nevertheless prove useful.
module OpenRubyRMK::Karfunkel::TestClient
  include OpenRubyRMK::Common

  #The Common::Transformer instance used for messing with
  #the protocol’s XML.
  attr_reader :transformer
  #Client ID used when talking to Karfunkel. Remember
  #to set this when talking to Karfunkel with anything
  #other than +hello+ requests.
  attr_accessor :id

  #Currently running testcase. Set by TestCase::run!.
  def self.current_test_case
    @current_test_case
  end

  #Set the currently running testcase. Used by TestCase::run!
  #and should never be called from elsewhere.
  def self.current_test_case=(test_case)
    @current_test_case = test_case
  end

  #Called by EventMachine when the connection to Karfunkel has
  #been established. Don’t call this manually.
  def post_init
    # Initialisation
    @last_request_id = 0
    @id_mutex        = Mutex.new
    @transformer     = Transformer.new
    @id              = -1

    # Let the testcase know the client that runs it
    OpenRubyRMK::Karfunkel::TestClient.current_test_case.client = self

    # Allow the testcase to be initialised
    OpenRubyRMK::Karfunkel::TestClient.current_test_case.execute_at(:startup)
  end

  #Called by EventMachine when Karfunkel sent data to us.
  #Don’t call this manually.
  def receive_data(data)
    cmd = @transformer.parse!(data)

    cmd.requests.each     {|request|  OpenRubyRMK::Karfunkel::TestClient.current_test_case.submit_request(request)  }
    cmd.responses.each    {|response| OpenRubyRMK::Karfunkel::TestClient.current_test_case.submit_response(response)}
    cmd.notifications.each{|note|     OpenRubyRMK::Karfunkel::TestClient.current_test_case.submit_notification(note)}
  end

  #Called by EventMachine when the connection to Karfunkel has
  #been closed. Don’t call this manually.
  def unbind
    OpenRubyRMK::Karfunkel::TestClient.current_test_case.execute_at(:shutdown)
    OpenRubyRMK::Karfunkel::TestClient.current_test_case.client = nil

    # When we’ve been disconnected, there’s nothing more to do for us.
    EventMachine.stop_event_loop
  end

  #Threadsafely generate a request ID you can use for sending
  #something to Karfunkel.
  def generate_request_id
    @id_mutex.synchronize do
      @last_request_id += 1
    end
  end

  #Deliver a Common::Command instance to Karfunkel by first
  #transforming it to XML and then appending the end-of-command
  #marker, then sending it out.
  def deliver(cmd)
    xml = Transformer.convert!(cmd)
    xml << Command::END_OF_COMMAND
    send_data(xml)
  end

end

#Base class for testing Karfunkel’s functionality via simulating
#requests, responses and notifications (and of course receiving
#them). In contrast to the usual unit testing defining a testcase
#works a bit different because Karfunkel’s event-driven nature
#prevents linear testing. Instead, you instanciate this class
#for your tests and call one of the test_* methods to define
#specific tests. These tests will then be called when an event of
#the type you registered for occurs. For example, you might
#define a test for the +foo+ request:
#
#  test_request :foo |req|
#    assert_equal("This is a foo", req.para1)
#  end
#
#When Karfunkel now sends you any kind of +foo+ request, this event
#handler will be called and your test will be executed.
#
#==Test Conditions
#However, an evented test like the above is triggered for *any* +foo+
#request. If you get multiple requests of this type which differ in
#their parameter structure and you want to setup different tests for
#them, you can pass a +conditions+ hash to the test_* methods. This
#conditions hash matches exactly on the request’s parameters, so
#if you expect two +foo+ requests, where the first one’s +para1+ is
#set to "This is foo" and the second one’s +para1+ to "This is foobar",
#you can setup two different tests like this:
#
#  test_request :foo, :para1 => "This is foo" do |req|
#    # Do some tests...
#  end
#
#  test_request :foo, :para1 => "This is foobar" do |req|
#    # Do some different tests...
#  end
#
#The same applices for responses and notifications, respectively.
#
#==Sending Requests, etc.
#You probably want to send requests to Karfunkel during the
#test to see if he responds correctly. You can make use of
#the #request, #requests, #response, #responses, #note, and
#the #notes methods for sending commands of the appropriate types.
#
#  request :foo, :para1 => "Some parameter value",
#                :para2 => "Some other parameter value"
#
#==Namespacing
#This class <tt>include</tt>s the OpenRubyRMK::Common namespace,
#so you don’t have to fully resolve +OpenRubyRMK::Common::Request+
#if you want to create a new request (if you refuse to use
#the helper methods described under _Sending Requests_ above)
#directly, but can just use +Request+.
#
#Furthermore, it mixes in Minitest::Assertions, providing the
#familiar test assertions such as +assert_equal+.
#
#==Initialisation and finalisation
#The Karfunkel::TestCase class provides you with four
#events related to initialisation and finalisation of
#your tests. These are, in the order in which they’re
#executed:
#
#[startup]
#  Run prior to any test, directly after the connection
#  to Karfunkel has been established. This is where you
#  want to issue a +hello+ request.
#[setup]
#  Run immediately before each test is executed. This means
#  that this code is executed the same number of times as
#  you have tests.
#[teardown]
#  Counterpart to +setup+, run immediately after each test.
#[shutdown]
#  Run after all tests have finished and the connection to
#  Karfunkel has been closed. Counterpart to +startup+.
#
#Use the #at method together with a symbol indicating the
#event you want to register for:
#
#  at :startup do
#    puts "Starting up!"
#  end
#  at :teardown do
#    puts "I've finished a test!"
#  end
#
#==Unconditional execution
#There may be times where you want to pursue Karfunkel with
#a request completely unrelated to any currently running
#communication. The easy method to achieve this is to use
#the #wait method which immediately returns and registers
#your block for execution after a specified number of seconds;
#inside this block, you can then issue your requests.
#
#  wait(10){request :foo}
#
#When the method described above doesn’t suffice, this doesn’t
#mean you’re stuck. The test client rides on top of
#EventMachine[http://rubyeventmachine.com], so you can use any
#of the vast number of methods supplied by EventMachine (indeed
#the #wait method is just a wrapper around EventMachine.add_timer).
#For instance, if you have a long-running operation and want to run
#it in the background, plus having a callback run when the operation
#has finished, you can use {EventMachine.defer}[http://eventmachine.rubyforge.org/EventMachine.html#M000486]:
#
#  longrunning_operation = lambda{your_operation_code_here}
#  callback              = lambda{|result| your_code_here}
#  EventMachine.defer(longrunning_operation, callback)
class OpenRubyRMK::Karfunkel::TestCase
  include OpenRubyRMK::Common
  include MiniTest::Assertions

  #Structure that encapsulates a single test by its
  #name, the conditions under which the test shall be
  #executed, and the actual test code.
  Test = Struct.new(:type, :conditions, :block)

  #The test client. Set automatically, you shouldn’t
  #need this. Anonymous class (thanks to EventMachine)
  #mixing in OpenRubyRMK::Karfunkel::TestClient.
  attr_accessor :client

  #The name of the testcase, to be displayed when running it.
  attr_reader :name

  #All instances of this class. Needed for running all of
  #them at once with #run!.
  def self.test_cases
    @test_cases ||= []
  end

  #Create a new instance of this class. The block is evaluated
  #in the context of the newly created instance, so feel free
  #to call this class’ instance methods without receiver.
  def initialize(name, &block)
    @name               = name
    @request_tests      = []
    @response_tests     = []
    @notification_tests = []
    @at_procs           = {}
    @client             = nil

    instance_eval(&block)
    self.class.test_cases << self
  end

  #Execute an event handler registered with #at. Called from
  #TestClient.
  def execute_at(event) # :nodoc:
    @at_procs[event].call if @at_procs.has_key?(event)
  end

  #Search for an event handler fitting for the given request
  #and execute it if one is found.
  def submit_request(req) # :nodoc:
    print "Testing a #{req.type.upcase} request... "
    @request_tests.each do |test|
      if test.type.to_s == req.type && test.conditions.all?{|k, v| req[k.to_s] == v.to_s}
        execute_test(test, req)
        puts Paint["PASS", :green]
        return
      end
    end

    puts Paint["SKIP", :blue]
    puts(Paint["Unhandled request of type '#{req.type}' with parameters #{req.parameters.inspect}.", :blue])
  rescue MiniTest::Assertion => e
    puts Paint["FAIL", :red]
    puts Paint[e.message, :red]
    puts Paint[e.backtrace.join("\n\t"), :red]
  rescue => e
    puts Paint["ERROR", :yellow]
    puts Paint["#{e.class}: #{e.message}", :yellow]
    puts Paint[e.backtrace.join("\n\t"), :yellow]
  end

  #Search for an event handler fitting for the given response
  #and execute it if one is found.
  def submit_response(res) # :nodoc:
    print "Testing response to a #{res.request.type.upcase} request... "

    @response_tests.each do |test|
      if test.type.to_s == res.request.type && test.conditions.all?{|k, v| res[k.to_s] == v.to_s}
        execute_test(test, res)
        puts Paint["PASS", :green]
        return
      end
    end

    puts Paint["SKIP", :blue]
    puts(Paint["Unhandled response to a request of type '#{res.request.type}' with response parameters #{res.parameters.inspect}.", :blue])
  rescue MiniTest::Assertion => e
    puts Paint["FAIL", :red]
    puts Paint[e.message, :red]
    puts Paint[e.backtrace.join("\n\t"), :red]
  rescue => e
    puts Paint["ERROR", :yellow]
    puts Paint["#{e.class}: #{e.message}", :yellow]
    puts Paint[e.backtrace.join("\n\t"), :yellow]
  end

  #Search for an event handler fitting the given notification
  #and execute it if one is found.
  def submit_notification(note) # :nodoc:
    print "Testing a #{note.type.upcase} notification... "
    @notification_tests.each do |test|
      if test.type.to_s == note.type && test.conditions.all?{|k, v| note[k.to_s] == v.to_s}
        execute_test(test, note)
        puts Paint["PASS", :green]
        return
      end
    end

    puts Paint["SKIP", :blue]
    puts(Paint["Unhandled notification of type '#{note.type}' with parameters #note.parameters.inspect}.", :blue])
  rescue MiniTest::Assertion => e
    puts Paint["FAIL", :red]
    puts Paint[e.message, :red]
    puts Paint[e.backtrace.join("\n\t"), :red]
  rescue => e
    puts Paint["ERROR", :yellow]
    puts Paint["#{e.class}: #{e.message}", :yellow]
    puts Paint[e.backtrace.join("\n\t"), :yellow]
  end

  #Runs this testcase.
  #
  #Karfunkel itself must be started prior to calling this method.
  #==Parameters
  #[host] ("localhost") Where to find Karfunkel.
  #[port] (3141) The port on +host+ to connect to.
  def run!
    raise("Another testcase is running!") if OpenRubyRMK::Karfunkel::TestClient.current_test_case

    File.open("karfunkel.log", "w+") do |logfile|
      # Spawn server
      spawn("#{OpenRubyRMK::Karfunkel::Paths::BIN_DIR.join("karfunkel")} -d > karfunkel.log")
      # Wait until ready
      sleep 1 while logfile.gets !~ /PID/ # Log message when ready contains this word
    end

    # Run testcase
    OpenRubyRMK::Karfunkel::TestClient.current_test_case = self
    puts Paint["=== Running testcase '#@name' ===", :cyan]
    begin
      EventMachine.run do
        EventMachine.connect("localhost", 3141, OpenRubyRMK::Karfunkel::TestClient)
      end
    ensure
      pid_file = OpenRubyRMK::Karfunkel::Paths::TMP_DIR + "karfunkel.pid"
      if pid_file.file?
        Process.kill("SIGTERM", File.read(pid_file).to_i)
      end
    end
  end

  protected

  #Register to one of the four special events.
  #==Parameter
  #[event] One of: +startup+, +setup+, +teardown+, +shutdown+.
  #        See the class docs for further information.
  #==Remarks
  #If you register multiple handlers for an event, the one
  #registered last will win.
  def at(event, &block)
    @at_procs[event] = block
  end

  #call-seq:
  #  test_request(type [, conditions ]){|request|...}
  #
  #Introduces a handler for a request.
  #==Parameters
  #[type]       The request type to register for.
  #[conditions] ({}) Only trigger when a request of +type+
  #             contains the given parameters.
  #[request]    (*Block*) The Request instance that triggered this event.
  #==Example
  #  test_request :foo, :para1 => "My foo" do |req|
  #    # Test code...
  #  end
  def test_request(type, conditions = {}, &block)
    @request_tests << Test.new(type, conditions, block)
  end

  #call-seq:
  #  test_response(type [, conditions ]){|response|...}
  #
  #Introduces a handler for a response.
  #==Parameters
  #[type]       The request type to whose responses you want to listen for.
  #[conditions] ({}) Only trigger when the response for a request
  #             of +type+ contains the given parameters.
  #[request]    (*Block*) The Response instance that triggered this event.
  #==Example
  #  test_response :foo, :para1 => "My foo" do |res|
  #    # Test code...
  #  end
  def test_response(type, conditions = {}, &block)
    @response_tests << Test.new(type, conditions, block)
  end

  #call-seq:
  #  test_note(type [, conditions ]){|note|...}
  #
  #Introduces a handler for a request.
  #==Parameters
  #[type]       The notification type to register for.
  #[conditions] ({}) Only trigger when a notification of +type+
  #             contains the given parameters.
  #[note]       (*Block*) The Notification instance that triggered this event.
  #==Example
  #  test_note :foo, :para1 => "My foo" do |req|
  #    # Test code...
  #  end
  def test_note(type, conditions = {}, &block)
    @notification_tests << Test.new(type, conditions, block)
  end

  #Constructs a request and delivers it.
  #==Parameters
  #[type] The type of the request to deliver.
  #[hsh]  ({}) Any options to set on the request.
  #==Return value
  #The Request instance delivered.
  def request(type, hsh = {})
    cmd = Command.new(@client.id)
    req = Request.new(@client.generate_request_id, type)
    hsh.each_pair{|k, v| req[k] = v}
    cmd << req
    deliver(cmd)

    req
  end

  #call-seq:
  #  requests(*<type, [hsh]>) → an_array
  #
  #Constructs a whole bunch of requests and delivers them as
  #a single command.
  #==Parameters
  #An arbitrary number of type-hash pairs, where each hash will
  #be used to construct options for the preceding type.
  #==Return value
  #An array of Request instances delivered.
  #==Example
  #  requests :foo, {:op1 => 1, :op2 => "foo"},
  #           :bar, nil, # Pass nil if you don’t need any options
  #           :baz, {:foobar => 33}
  def requests(*args)
    cmd = Command.new(@client.id)
    args.each_slice(2) do |type, hsh|
      hsh = {} if hsh.nil?
      req = Request.new(@client.generate_request_id, type)
      hsh.each_pair{|k, v| req[k] = v}
      cmd << req
    end
    deliver(cmd)

    cmd.requests
  end

  #Constructs a response and delivers it.
  #==Parameters
  #[req]    The request to answer.
  #[status] The response status.
  #[hsh]    ({}) Any options to set on the response.
  #==Return value
  #The Response instance delivered.
  def response(req, status, hsh = {})
    cmd = Command.new(@client.id)
    res = Response.new(@client.generate_request_id, status, req)
    hsh.each_pair{|k, v| res[k] = v}
    cmd << res
    deliver(cmd)

    res
  end

  #call-seq:
  #  responses(*<req, status, [hsh]>)
  #
  #Constructs a whole bunch of responses and delivers them as
  #a single command.
  #==Parameters
  #An arbitary number of triplets specifying the status of
  #a response and options to set on it.
  #==Return value
  #An array of Response instances delivered
  #==Example
  #  responses req1, :ok, nil, # Use nil if you don’t need any options
  #            req2, :rejected, {:reason => "I don’t like you."}
  def responses(*args)
    cmd = Command.new(@client.id)
    args.each_slice(3) do |req, status, hsh|
      hsh = {} if hsh.nil?
      res = Response.new(@client.generate_request_id, status, req)
      hsh.each_pair{|k, v| res[k] = v}
      cmd << res
    end
    deliver(cmd)

    cmd.responses
  end

  #Constructs a notification and delivers it.
  #==Parameters
  #[type] The type of the notification to deliver.
  #[hsh]  ({}) Any options to set on the notification.
  #==Return value
  #The Notification instance delivered.
  def note(type, hsh = {})
    cmd  = Command.new(@client.id)
    note = Notification.new(@client.generate_request_id, type)
    hsh.each_pair{|k, v| note[k] = v}
    cmd << note
    deliver(cmd)

    note
  end

  #call-seq:
  #  notes(*<type, [hsh]>) → an_array
  #
  #Constructs a whole bunch of notifications and delivers them as
  #a single command.
  #==Parameters
  #An arbitrary number of type-hash pairs, where each hash will
  #be used to construct options for the preceding type.
  #==Return value
  #An array of Notification instances delivered.
  #==Example
  #  notes :foo, {:op1 => 1, :op2 => "foo"},
  #        :bar, nil, # Pass nil if you don’t need any options
  #        :baz, {:foobar => 33}
  def notes(*args)
    cmd = Command.new(@client.id)
    args.each_slice(2) do |type, hsh|
      hsh  = {} if hsh.nil?
      note = Notification.new(@client.generate_request_id, type)
      hsh.each_pair{|k, v| note[k] = v}
      cmd << note
    end
    deliver(cmd)

    cmd.notifications
  end

  #Waits the given amount of seconds and then executes the
  #given block. This operation is non-blocking, i.e. this
  #method immediately returns, the block is run in parallel.
  #==Parameter
  #[secs] The number of seconds to wait before executing
  #       the block. If you don’t care exactly, you may
  #       utilize Ruby’s #rand method.
  #==Example
  #  puts "Foo"
  #  wait(1){puts "Block!"}
  #  puts "Bar"
  #  sleep 2
  #  puts "Baz"
  #Result:
  #  Foo
  #  Bar
  #  Block!
  #  Baz
  def wait(secs, &block)
    EventMachine.add_timer(secs, &block)
  end

  #Transforms a Command instance to XML, appends the command
  #separator and delivers the result to Karfunkel.
  #==Parameter
  #[cmd] The Command instance to deliver.
  def deliver(cmd)
    xml = @client.transformer.convert!(cmd)
    xml << Command::END_OF_COMMAND
    @client.send_data(xml)
  end

  private

  #Calls #setup, executes the test, then calls #teardown.
  #The testcodeblock gets passed +obj+ as a parameter.
  def execute_test(test, obj)
    execute_at(:setup)
    test.block.call(obj)
    execute_at(:teardown)
  end

end
