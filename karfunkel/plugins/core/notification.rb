# -*- coding: utf-8 -*-

#A Notification is a broadcast message that is sent to all clients currently
#connected to the OpenRubyRMK server. As with requests and responses, it’s
#just a part of the Command container structure. Notifications can be
#created inside the Request DSL via the #broadcast method.
class OpenRubyRMK::Karfunkel::Plugins::Core::Notification
  
  #The type of this notification. Used to distinguish notifications
  #for e.g. easier translations.
  attr_accessor :type
  #All information associated with this notification as a hash whose
  #keys and values are strings.
  attr_accessor :attributes

  #The Core::Client who sent the Notification. Should be Karfunkel
  #because it’s the server’s job to deliver messages to
  #everyone. Even if you call #broadcast inside a request, all
  #you do is to instruct Karfunkel to send a message to all
  #connected clients--you don’t send the message yourself. You
  #wouldn’t be able to either, because you don’t have the list
  #of all clients and how to reach them.
  attr_reader :sender
  
  #Creates a new Notification. There shouldn’t be a need for you to
  #call this directly.
  #==Parameters
  #[sender]     The client the notifications comes from. Should be the
  #             Karfunkel himself.
  #[type]       The type of the notification. You can freely choose a
  #             symbol fitting your needs, currently there isn’t a list
  #             of allowed notifications.
  #[attributes] ({}) The content of the notification. The keys and
  #             values will show up in the resulting XML. Note
  #             that both keys and values will be converted to
  #             strings by calling their #to_s method.
  #==Return value
  #The newly created instance.
  #==Example
  #  note = OpenRubyRMK::Karfunkel::Notification.new(OpenRubyRMK::Karfunkel::THE_INSTANCE, :foo, :my_foo => 3)
  def initialize(sender, type, attributes = {})
    @sender = sender
    @type = type.to_s
    #Convert keys and values to strings
    @attributes = Hash[attributes.map{|k, v| [k.to_s, v.to_s]}]
  end
  
  #Grep the specified attribute from the notification.
  #==Parameter
  #[attribute] The key you want to look up.
  #==Return value
  #The value for the attribute or nil if it couldn’t be found.
  #If a value is found, it will always be a string.
  #==Example
  #  note[:my_foo]  #=> "3"
  #  note["my_foo"] #=> "3"
  #  note["blabla"] #=> nil
  def [](attribute)
    @attributes[attribute.to_s]
  end
  
  #Set an attribute for this notification.
  #==Parameters
  #[attribute] The key you want to set. Converted to a string by #to_s.
  #[value]     The value you want to assign. Converted to a string by #to_s.
  #==Example
  #  note[:my_foo] = 3
  #  # Same as
  #  note["my_foo"] = 3
  def []=(attribute, value)
    @attributes[attribute.to_s] = value.to_s
  end
  
  #call-seq:
  #  eql?(another_note)     → a_bool
  #  a_note == another_note → a_bool
  #
  #Compares two notifications. They’re considered equal if both the type
  #and the arguments are equal.
  #==Parameter
  #[other] Something that responds to :type and :attributes, ideally
  #        a Notification instance.
  #==Example
  #  note1.attributes #=> {"foo" => "3"}
  #  note2.attributes #=> {"foo" => "4"}
  #  note1 == note2   #=> false
  #  note2["foo"] = 3
  #  note1 == note2   #=> true
  def ==(other)
    return false if !other.respond_to?(:type) or !other.respond_to?(:attributes)
    @type == other.type and @attributes == other.attributes
  end
  alias eql? ==
  
end
