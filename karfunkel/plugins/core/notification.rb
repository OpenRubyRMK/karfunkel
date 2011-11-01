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

  #The Client who sent the Notification. Should be the Karfunkel
  #module, because it’s the server’s job to deliver messages to
  #everyone. Even if you call #broadcast inside a request, all
  #you do is to instruct Karfunkel to send a message to all
  #connected clients--you don’t send the message yourself. You
  #wouldn’t be able to either, because you don’t have the list
  #of all clients and how to reach them.
  attr_reader :sender
  
  #Creates a new Notification. There shouldn’t be a need for you to
  #call this directly.
  def initialize(sender, type, attributes = {})
    @sender = sender
    @type = type.to_s
    #Convert keys and values to strings
    @attributes = Hash[attributes.map{|k, v| [k.to_s, v.to_s]}]
  end
  
  def [](attribute)
    @attributes[attribute.to_s]
  end
  
  def []=(attribute, value)
    @attributes[attribute.to_s] = value.to_s
  end
  
  #Compares two notifications. They’re considered equal if both the type
  #and the arguments are equal.
  def ==(other)
    return false if !other.respond_to?(:type) or !other.respond_to?(:attributes)
    @type == other.type and @attributes == other.attributes
  end
  
end
