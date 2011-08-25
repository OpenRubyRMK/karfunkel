#Encoding: UTF-8

module OpenRubyRMK::Karfunkel::SM
  
  #A Notification is a broadcast message that is sent to all clients currently
  #connected to the OpenRubyRMK server. As with requests and responses, it’s
  #just a part of the Command container structure. Notifications can be
  #created inside the Request DSL via the #broadcast method.
  class Notification
    
    #The type of this notification. Used to distinguish notifications
    #for e.g. easier translations.
    attr_accessor :type
    #All information associated with this notification as a hash whose
    #keys and values are strings.
    attr_accessor :attributes
    
    #Creates a new Notification. There shouldn’t be a need for you to
    #call this directly.
    def initialize(type, attributes = {})
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
  
  
end