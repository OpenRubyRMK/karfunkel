#!/usr/bin/env ruby
#Encoding: UTF-8

require "term/ansicolor"
require "pathname"
require "socket"
require "erb"
require "timeout"

class TestCUI
  
  END_OF_COMMAND = "\0".freeze
  
  THIS_DIR = Pathname.new(__FILE__).dirname.expand_path
  
  T = Term::ANSIColor
  
  DUMMY = BasicObject.new
  
  def DUMMY.method_missing(*)
    puts T.red("You have to >>greet<< first!")
  end
  
  def initialize(argv)
    @argv = argv
    @request_id = 0
    @sock = DUMMY
  end
  
  def start
    puts T.red("Karfunkel testing CUI.")
    puts "List commands with 'help'. Exit with 'exit'."
    loop do
      print T.blue("?> ")
      line = $stdin.gets.chomp
      break if line == "exit"
      cmd, *args = line.split
      
      sym = :"cmd_#{cmd}"
      if respond_to?(sym, true) #Include private methods
        begin
          send(sym, *args)
        rescue ArgumentError => e
          puts T.red(e.message)
        rescue => e
          puts T.red("#{e.class}: #{e.message}")
          e.backtrace.each{|t| puts T.red("\t#{t}")}
        end
      else
        puts T.red("#{cmd} is not a valid command.")
      end
    end
    puts T.red("Finished.")
  end
  
  private
  
  def cmd_raw(str)
    @sock.write(str + END_OF_COMMAND)
    puts T.yellow(@sock.gets(END_OF_COMMAND))
  end
  
  def cmd_reset_request_id(val)
    @request_id = val.to_i
  end
  
  def cmd_help
    puts "Possible commands are:"
    private_methods.map(&:to_s).select{|s| s.start_with?("cmd_")}.sort.each do |str|
      puts str.sub(/^cmd_/, "")
    end
  end
  
  def cmd_greet(port)
    @port = port
    @sock = TCPSocket.open("localhost", @port)
    render :hello
  end
  
  def cmd_clear
    system("clear")
  end
  
  def cmd_get
    puts T.yellow(@sock.gets(END_OF_COMMAND))
  end
  
  def cmd_open_project(file)
    render :open_project, :file => file
  end
  
  def cmd_observe(secs)
    Timeout.timeout(secs) do
      loop do
        puts T.yellow(@sock.gets(END_OF_COMMAND))
      end
    end
  end
  
  def cmd_pong(ping_id)
    render :pong, :ping_id => ping_id
  end
  
  def render(template_name, info = {})
    cmd = ERB.new(THIS_DIR.join(template_name.to_s + ".xml").read).result(binding)
    cmd << END_OF_COMMAND
    @request_id += 1
    @sock.write(cmd)
    puts T.yellow(@sock.gets(END_OF_COMMAND))
  end
  
end

TestCUI.new(ARGV).start