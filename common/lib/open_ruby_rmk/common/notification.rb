# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  #Notifications are messages delivered from the server to all connected
  #clients. In contrast to requests, they don’t need to be answered and
  #only serve informational purposes.
  #
  #As with requests and responses, they’re part of a Command instance and
  #their external representation is an XML structure, this time a tag
  #named NOTIFICATION. Inside it, you will find zero or more parameter
  #tags that contain the real information this notification wants to
  #deliver.
  #
  #Notifications can only be created by Karfunkel; this is due to the
  #fact he is the only one knowing about all active connections. If you
  #want to share some information with other clients, you have to send
  #it to Karfunkel first.
  #
  #== Notification types
  #A notification’s _type_ gives a simple outline about what to find
  #inside the tags of this notification. Karfunkel only
  #sends a limited number of notification types, which you may look up
  #in Karfunkel’s own documentation.
  #
  #== Sample XML
  #=== With parameters
  #  <notification type="foo" id="556">
  #    <par1>Parameter 1</par1>
  #    <par2>Parameter 2</par2>
  #  </notification>
  #=== Without parameters
  #  <notification type="foo" id="556"/>
  class Notification

    #The (hopefully) unique notification ID.
    attr_reader :id
    #This notification’s type as a *string* as it comes directly
    #from the XML.
    attr_reader :type
    #The key-value pairs making up this notification. As this is
    #parsed from the XML, both keys and values are *strings*.
    attr_accessor :parameters

    #Creates a new instance of this class.
    #==Parameters
    #[id]   Some unique ID for this notification.
    #[type] The type of this request.
    #==Return value
    #The newly created instance.
    #==Example
    #  note = Notification.new(4, "project-created")
    def initialize(id, type)
      @id         = id
      @type       = type.to_s
      @parameters = {}
    end

    #Reads a parameter from this notification.
    #==Parameter
    #[par] The name of the parameter you want to read.
    #      Automatically converted to a string by calling #to_s.
    #==Return value
    #nil if no matching parameter is found, a string otherwise.
    #==Example
    #  note = Notification.new(1, "Foo")
    #  note["foo"] = "bar"
    #  note[:abc]  = 33
    #   
    #  note["foo"] #=> "bar"
    #  note[:foo]  #=> "bar"
    #  note[:abc]  #=> "33"
    #  note["abc"] #=> "33"
    def [](par)
      @parameters[par.to_s]
    end

    #Sets a parameter of this notification.
    #==Parameters
    #[par]   The name of the parameter you want to set. This is
    #        automatically converted by calling #to_s.
    #[value] The value of the parameter. Converted to a string
    #        by calling #to_s as well.
    #==Return value
    #Exactly +value+, as the Ruby interpreter enforces this.
    #==Example
    #  note = Notification.new(1, "Foo")
    #  note["foo"] = "bar"
    #  note[:abc]  = 33
    #   
    #  note["foo"] #=> "bar"
    #  note[:foo]  #=> "bar"
    #  note[:abc]  #=> "33"
    #  note["abc"] #=> "33"    
    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end
    
    #Compares two notifications. They’re considered equal if they
    #have the same type and id.
    def eql?(other)
      return nil unless other.respond_to?(:type) and other.respond_to?(:id)
      @type == other.type && @id == other.id
    end
    alias == eql?

    #Human-readable description of form:
    #  <OpenRubyRMK::Common::Notification <TYPE> (<id>)
    def inspect
      "#<#{self.class} #{@type.upcase} (#@id)>"
    end

  end

end
