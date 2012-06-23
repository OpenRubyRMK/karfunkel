# -*- coding: utf-8 -*-

module OpenRubyRMK::Karfunkel::Plugin::Base

  #A _cageroy_ encapsulates all information from a special
  #kind of resource in the ORR. These resources include
  #items, weapons, skills and everything else that occurs
  #in a great number with configurable subattributes.
  #
  #For example, the (predefined) category _items_ (represented
  #by an instance of this class) holds a list of items defined
  #by the user. Each item in this category has a specific number
  #of attributes (i.e. each item has the *same* attributes, but
  #most likely with different values assigned to them) and is
  #represented by an instance of class Cagegory::Entry. Finally,
  #the items’ attributes can be accessed by means of the
  #Category::Entry#[] and Category::Entry[]= methods which
  #will convert both attribute names and values to strings
  #automatically, because this information will be exported
  #to XML which doesn’t know anbout anything else.
  #
  #==Sample XML
  #  <category name="items">
  #    <entry>
  #      <attribute name="name">FooItem</attribute>
  #      <attribute name="type">Fire</attribute>
  #    </entry>
  #    <entry>
  #      <attribute name="name">BlaItem</attribute>
  #      <attribute name="type">Water</attribute>
  #    </entry>
  #  </category>
  class Category

    #An entry in a category.
    class Entry

      #All attributes (and their values) for this
      #entry. Don’t modify this directly, use the
      #methods provided by this class.
      attr_reader :attributes

      #Creates a new and empty entry.
      def initialize
        @attributes = {}
      end

      #Gets the value of the named attribute. +name+ will
      #be converted to a string and the return value also
      #is a string.
      def [](name)
        @attributes[name.to_s]
      end

      #Sets the value of the named attribtue. +name+
      #and +val+ will be converted to strings.
      def []=(name, val)
        @attributes[name.to_s] = val.to_s
      end

      #Iterates over all attribute names and values.
      def each_attribute(&block)
        @attributes.each_pair(&block)
      end

      #Deletes the attribute +name+ (which is converted
      #to a string if necessary).
      def delete(name)
        @attributes.delete(name.to_s)
      end

    end

    #All entries in this category.
    attr_reader :entries

    #Load an entire category from the XML file at +path+.
    #Return value is an instance of this class.
    def self.load(path)
      File.open(path) do |file|
        obj = allocate
        obj.instance_eval do
          xml = Nokogiri::XML(file)
          @name = xml.root["name"]
          @entries = []

          xml.xpath("//entry").each do |entry|
            item = Entry.new
            entry.xpath("attribute").each do |attr|
              item[attr["name"]] = attr.text
            end
            @entries << item
          end
        end

        obj
      end
    end

    #Create a new and empty category. +name+ will
    #be converted to a string.
    def initialize(name)
      @name    = name.to_s
      @entries = []
    end

    #The attributes the entries in this category have.
    #An array of strings.
    def attributes
      # All entries should have the same attributes
      @entries.first.attributes.keys
    end

    #Add a new attribute to each entry in this category.
    #The set value will be an empty string.
    def add_attribute(name)
      @entries.each do |entry|
        entry[name] = nil
      end
    end

    #Removes an attribute (plus value) from each entry
    #in this category.
    def delete_attribute(name)
      @entries.each do |entry|
        entry.delete(name)
      end
    end

    #Saves the entire category to the XML file +path+.
    def save(path)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml1|
        xml1.category(:name => "item") do |xml2|
          @entries.each do |item|
            xml2.entry do |xml3|
              item.each_attribute do |name, val|
                xml3.attribute(val, :name => name)
              end
            end
          end
        end
      end

      File.open(path, "w"){|file| file.write(builder.to_xml)}
    end

  end

end
