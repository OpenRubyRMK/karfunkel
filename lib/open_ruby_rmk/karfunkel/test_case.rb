# -*- coding: utf-8 -*-
require "minitest/unit"
require "eventmachine"
require "paint"
require_relative "../karfunkel"

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
#The same applies for responses and notifications, respectively.
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
#
# == Internal stuff
#
# Internally, the asynchronous testing mechanism works by specifying
# a micro protocol module to EventMachine, TestCase::ORRTP, which
# basically does nothing more than notifying the currently running
# testcase of the fact that data has arrived. It actually does a
# bit more, like automatically converting the received data to
# proper instances of the Request, Response, and Notification
# classes, but that’s the basic idea. The data is handed to the
# testcase (via TestCase#submit, which is not visible in the
# RDoc output by default), which calls the handler registered
# for this kind of command object (request, response, notification)
# and also takes care of calling the +setup+ and +teardown+ methods
# for this test. Note that when using a real concurrent Ruby implementation
# such as Rubinius, it is possible that two or even more handlers
# run *really* at the same time. The test case the ORRTP module
# calls out to, is moved around in a global variable <tt>$test_case</tt>,
# should you ever need it; see the code for reasoning why to use
# a global here.
class OpenRubyRMK::Karfunkel::TestCase
  include OpenRubyRMK::Common
  include MiniTest::Assertions

  # Beware the global variables! However, this one significantly
  # eases the work needed for keeping track of the connection we
  # have to the server. As there can only be one test case running
  # at a time needing exactly one connection, there shouldn’t arise
  # any access problems. The connection object needs the test case
  # for notifying it of data received, and the testcase object needs
  # the connection object for sending data; however, the one and
  # only way to get hold of the connection object is to assign it
  # inside the #post_init hook method of the module handed to
  # EventMachine. Note a singleton wouldn’t do neither,
  # because although there can only be one test case at a time,
  # to different times it may well be different test cases. The
  # most prominent place where this happens is a (one-process)
  # Rake task running all test cases one after the other.
  $test_case = nil # OpenRubyRMK::Karfunkel::TestCase object

  # Micro EventMachine protocol module used for the communication
  # with the server. It does nothing beside receiving data, transforming
  # it to Request, Response, and Notification objects, and then
  # pass them on to the currently running <tt>$test_case</tt>. It
  # also has a #deliver method for the reverse process of transforming
  # a Request, Response, or Notification object to raw data and send
  # that to the server.
  module ORRTP # OpenRubyRMK Testing Protocol ;-)

    #The Common::Transformer instance used for messing with
    #the protocol’s XML.
    attr_reader :transformer
    #Client ID used when talking to Karfunkel. Remember
    #to set this when talking to Karfunkel with anything
    #other than +hello+ requests.
    attr_accessor :id

    #Called by EventMachine when the connection to Karfunkel has
    #been established. Don’t call this manually.
    def post_init
      raise("FATAL: No test case running that we could inform of events!") unless $test_case

      # Initialisation
      @last_request_id = 0
      @id_mutex        = Mutex.new
      @transformer     = OpenRubyRMK::Common::Transformer.new
      @id              = -1

      # Let the testcase know the client that runs it
      $test_case.connection = self

      # Allow the testcase to be initialised
      begin
        $test_case.execute_at(:startup)
      rescue => e
        puts e.name
        puts e.message
        puts e.backtrace.join("\n\t")
        raise
      end
    end

    # Called by EventMachine when Karfunkel sent data to us. Transforms
    # the received data to Request/Response/Notification objects and then
    # hands it out to the test case.
    def receive_data(data)
      data.split("\0").each do |xml|
        cmd = @transformer.parse!(xml)

        cmd.requests.each     {|request|  $test_case.submit(request) }
        cmd.responses.each    {|response| $test_case.submit(response)}
        cmd.notifications.each{|note|     $test_case.submit(note)    }
      end
    end

    #Called by EventMachine when the connection to Karfunkel has
    #been closed. Don’t call this manually.
    def unbind
      $test_case.execute_at(:shutdown)
      $test_case.connection = nil

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
      xml = @transformer.convert!(cmd)
      xml << OpenRubyRMK::Common::Command::END_OF_COMMAND
      send_data(xml)
    end

  end

  #Structure that encapsulates a single test by its
  #name, the conditions under which the test shall be
  #executed, and the actual test code.
  Test = Struct.new(:type, :conditions, :block)

  # The connection to the server. This is the anonymous
  # subclass of EM::Connection mixing in the ORRTP module
  # and is created by EventMachine and assigned to this
  # variable automatically in ORRTP#post_init. You most likely
  # won’t access it directly.
  attr_accessor :connection

  #The name of the testcase, to be displayed when running it.
  attr_reader :name

  #Create a new instance of this class. The block is evaluated
  #in the context of the newly created instance, so feel free
  #to call this class’ instance methods without receiver.
  #
  #The +name+ parameter is a pretty name for the test case that
  #is printed out to the console when running the test case.
  def initialize(name, &block)
    @name               = name
    @request_tests      = []
    @response_tests     = []
    @notification_tests = []
    @at_procs           = {}
    @connection         = nil

    instance_eval(&block)
  end

  #Execute an event handler registered with #at. Called from
  #ORRTP when necessary.
  def execute_at(event) # :nodoc:
    @at_procs[event].call if @at_procs.has_key?(event)
  end

  # Called by ORRTP#receive_data. This method expects an
  # instance of Request, Response, or Notification and
  # searches for a handler registered for this kind of
  # command object. If one is found, the handler is executed
  # as a test (with the appropriate calls to the :setup and
  # :teardown hooks). Also prints a nice testing message.
  #
  # Do not call this yourself, this is only for
  # ORRTP#receive_data.
  def submit(obj) # :nodoc:
    # Determine what we got
    klass = obj.class.name.split("::").last.downcase
    tests = instance_variable_get("@#{klass}_tests") || raise(TypeError, "BUG: Unknown command object received!")

    print "Testing a #{klass} of type #{obj.type}... "

    # Search all event handlers for this type of command object
    # and execute the matching one if one is found.
    tests.each do |test|
      if obj.type.to_s == test.type.to_s && test.conditions.all?{|k, v| obj[k.to_s] == v.to_s} # Note `type' here refers to the `type=xxx' parameter in the XML of the command object
        execute_test(test, obj)
        puts Paint["PASS", :green] # If we get here, everything is fine
        return
      end
    end

    # If we get here, this command object is not handled.
    puts Paint["SKIP", :blue]
    puts Paint["Unhandled #{klass} of type '#{obj.type}' with parameters #{obj.parameters.inspect}.", :blue]
  rescue MiniTest::Assertion => e
    puts Paint["FAIL", :red]
    puts Paint[e.message, :red]
    puts Paint[e.backtrace.join("\n\t"), :red]
  rescue => e
    puts Paint["ERROR", :yellow]
    puts Paint["#{e.class}: #{e.message}", :yellow]
    puts Paint[e.backtrace.join("\n\t"), :yellow]
  end

  # Starts Karfunkel in the background, waits for it to become
  # ready (via the -S commandine switch) and then starts an
  # EventMachine loop for a client using the ORRTP protocol,
  # which talks back to the instance calling this and causes
  # the registered handlers to be executed.
  def run!
    raise("FATAL: There can only be one test case running at a time!") if $test_case

    # Prepare for receiving the ready message
    Signal.trap("SIGUSR1"){@server_ready = true}
    # Spawn server
    spawn("#{OpenRubyRMK::Karfunkel::Paths::BIN_DIR.join("karfunkel")} -d -S #$$ > karfunkel.log")
    # Wait until ready
    sleep 0.5 until @server_ready

    # Run testcase
    $test_case = self
    puts Paint["=== Running testcase '#@name' ===", :cyan]
    begin
      EventMachine.run do
        EventMachine.connect("localhost", 3141, ORRTP)
      end
    ensure
      pid_file = OpenRubyRMK::Karfunkel::Paths::TMP_DIR + "karfunkel.pid"
      if pid_file.file?
        Process.kill("SIGTERM", File.read(pid_file).to_i)
      end

      # Clean up the global test case variable so another
      # test case may run now.
      $test_case = nil
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
    cmd = Command.new(@connection.id)
    req = Request.new(@connection.generate_request_id, type)
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
    cmd = Command.new(@connection.id)
    args.each_slice(2) do |type, hsh|
      hsh = {} if hsh.nil?
      req = Request.new(@connection.generate_request_id, type)
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
    cmd = Command.new(@connection.id)
    res = Response.new(@connection.generate_request_id, status, req)
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
    cmd = Command.new(@connection.id)
    args.each_slice(3) do |req, status, hsh|
      hsh = {} if hsh.nil?
      res = Response.new(@connection.generate_request_id, status, req)
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
    cmd  = Command.new(@connection.id)
    note = Notification.new(@connection.generate_request_id, type)
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
    cmd = Command.new(@connection.id)
    args.each_slice(2) do |type, hsh|
      hsh  = {} if hsh.nil?
      note = Notification.new(@connection.generate_request_id, type)
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
  #
  #Forwards to ORRTP#deliver.
  #==Parameter
  #[cmd] The Command instance to deliver.
  def deliver(cmd)
    @connection.deliver(cmd)
  end

  private

  #Calls #setup, executes the test, then calls #teardown.
  #The testcodeblock gets passed +obj+ as a parameter.
  def execute_test(test, obj)
    begin
      execute_at(:setup)
      test.block.call(obj)
    ensure
      execute_at(:teardown)
    end
  end

end
