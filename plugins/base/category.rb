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
  #==Example
  #  # Create the new category
  #  items = Category.new("items")
  #
  #  # Add one entry to the items category
  #  item1 = Category::Entry.new(items)
  #  item1[:name] = "Hot thing"
  #  item1[:type] = "fire"
  #  items.entries << item1
  #
  #  # Add another item
  #  item2 = Category::Entry.new(items)
  #  item2[:name] = "Cool thing"
  #  item2[:type] = "ice"
  #  items.entries << item2
  #
  #  # Attributes used in this category
  #  # TODO: Enforce the same attributes for every entry
  #  p items.attributes #=> ["name", "type"]
  #
  #  # Save it out to disk
  #  items.save("items.xml")
  #  # Reload it
  #  items = Category.load("items.xml")
  #  p items.entries.count #=> 2
  #==Sample XML
  #  <category name="items">
  #    <entry>
  #      <attribute name="name">Hot thing</attribute>
  #      <attribute name="type">fire</attribute>
  #    </entry>
  #    <entry>
  #      <attribute name="name">Cool thing</attribute>
  #      <attribute name="type">ice</attribute>
  #    </entry>
  #  </category>
  class Category
    include Enumerable

    #Thrown when you try to create an entry with an attribute
    #not allowed in the entry’s category.
    class UnknownAttribute < OpenRubyRMK::Errors::OpenRubyRMKError

      #The entry where you wanted to add the attribute.
      attr_reader :entry
      #The name of the attribute.
      attr_reader :attribute_name

      #Create a new exception of this class.
      #==Parameters
      #[entry] The problematic entry.
      #[attr]  The name of the faulty attribute.
      #[msg]   (nil) Your custom error message.
      #==Return value
      #The new exception.
      def initialize(entry, attr, msg = nil)
        super(msg || "The attribute #{attr} is not allowed in the #{entry.category} category.")
        @entry          = entry
        @attribute_name = attr
      end

    end

    #An entry in a category.
    class Entry

      #The Category object this entry belongs to.
      attr_reader :category

      #All attributes (and their values) for this
      #entry. Don’t modify this directly, use the
      #methods provided by this class.
      attr_reader :attributes

      #Creates a new and empty entry.
      #==Parameter
      #[category] The Category instance this entry shall belong to.
      #==Return value
      #The new instance.
      def initialize(category)
        @category   = category
        @attributes = Hash.new{|hsh, k| hsh[k] = ""}
      end

      #Gets the value of the named attribute. +name+ will
      #be converted to a string and the return value also
      #is a string.
      def [](name)
        name = name.to_s
        raise(UnknownAttribute.new(self, name)) unless @category.allowed_attributes.include?(name)

        @attributes[name]
      end

      #Sets the value of the named attribtue. +name+
      #and +val+ will be converted to strings.
      def []=(name, val)
        name = name.to_s
        raise(UnknownAttribute.new(self, name)) unless @category.allowed_attributes.include?(name)

        @attributes[name] = val.to_s
      end

      #Iterates over all attribute names and values.
      def each_attribute(&block)
        @attributes.each_pair(&block)
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
          xml                 = Nokogiri::XML(file)
          @name               = xml.root["name"]
          @allowed_attributes = []
          @entries            = []

          xml.xpath("//entry").each do |entry|
            item = Entry.new(self)
            entry.xpath("attribute").each do |attr|
              add_attribute(attr["name"]) # NOP if already in
              item[attr["name"]] = attr.text
            end
            @entries << item
          end
        end

        obj
      end
    end

    #All attribute names allowed for entries in this
    #category.
    attr_reader :allowed_attributes
    #All Entry instances associated with this category.
    attr_reader :entries

    ##
    # :attr_accessor: name
    #The category’s name.

    #Create a new and empty category.
    def initialize(name)
      @name               = name.to_str
      @allowed_attributes = []
      @entries            = []
    end

    #See accessor.
    def name=(str) # :nodoc:
      @name = str.to_str
    end

    #See accessor.
    def name
      @name
    end

    #Adds an Entry to this category.
    def add_entry(entry)
      @entries.push(entry)
    end

    #Same as #add_entry, but returns +self+ for method
    #chaining.
    def <<(entry)
      add_entry(entry)
      self
    end

    #Iterates over each Entry in this Category.
    def each(&block)
      @entries.each(&block)
    end

    #Add a new attribute to each entry in this category.
    #The set value will be an empty string.
    #If the attribute is already allowed, does nothing.
    def add_attribute(name)
      name = name.to_s
      return if @allowed_attributes.include?(name)

      @allowed_attributes << name
      @entries.each do |entry|
        entry[name] = nil
      end
    end

    #Removes an attribute (plus value) from each entry
    #in this category.
    #If this attribute wasn’t existant before, does nothing.
    def delete_attribute(name)
      name = name.to_s
      return unless @allowed_attributes.include?(name)

      @allowed_attributes.delete(name)
      @entries.each do |entry|
        entry[name] = nil
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
