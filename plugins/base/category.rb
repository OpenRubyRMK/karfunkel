# -*- coding: utf-8 -*-
module OpenRubyRMK::Karfunkel::Plugin::Base

  #Main class for managing _categories_, i.e. lists of common
  #configurable things like items, weapons, skills, etc. Each of
  #these is called a _category_, and you can have as many of them
  #as you want. A category has a fixed list of traits that may
  #be set on each entry inside this category. You can retrieve this
  #list of trait names by calling Category#traits which will
  #give you an array of strings, or #trait_names, which gives you
  #an array of instances of the underlying TraitName class. To
  #enable a new trait for entries in this category, use #add_trait
  #and for removing an existing one, call #delete_trait.
  #
  #For example, you could build up a small category called _items_ this way:
  #
  #  # First, create the category itself.
  #  items = Category.create(:name => "items")
  #
  #  # Then, add the traits entries in this category,
  #  # i.e. items, are allowed to have.
  #  items.add_trait("name")
  #  items.add_trait("type")
  #
  #  # Now let's create some real items.
  #  item1 = Entry.new(:category => items)
  #  item1[:name] = "Hot thing"
  #  item1[:type] = "fire"
  #  item1.save
  #
  #  item2 = Entry.new(:category => items)
  #  item2[:name] = "Cool thing"
  #  item2[:type] = "ice"
  #  item2.save
  #
  #You’re completely free in both the trait names and values. Note
  #however, that the vales are (currently) saved as strings in the
  #database, so you probably have to convert them. This may change
  #in the future.
  #
  #--
  #  Internal structure of the category-related classes
  #  (ERM plus info):
  #
  #            1    n        1    n
  #  Category <------ Entry <------ Trait
  #   1 ^                             ^
  #     |                             :
  #   n |          <influences>       :
  #  TraitName .......>.........>......
  #++
  class Category
    include DataMapper::Resource

    property :id, Serial
    property :name, String

    has n, :trait_names
    has n, :entries

    ##
    # :attr_accessor: name
    #The category’s name.

    ##
    # :attr_reader: trait_names
    #The underlying list of TraitName instances. DM query.

    ##
    # :attr_reader: entries
    #The entries (Entry instances) in this category. DM query.

    #Trait names allowed for entries in this category.
    #An array of strings.
    def traits
      trait_names.all(:fields => [:name]).map(&:name)
    end

    #Add a new allowed trait name for the category.
    #After a call to this, you will be able to set traits
    #of name +name+ via the Entry#[]= method for entries
    #in this category.
    def add_trait(name)
      TraitName.create(:name => name, :category => self)
    end

    #Remove an already existing trait name from this
    #category. All entries in this category will be edited
    #automatically and have this trait removed from them.
    def delete_trait(name)
      trait_names.first(:name => name).destory || raise("Error destroying trait #{name}!")
    end

  end

  #Class representing an entry in a specific category. Entries basically
  #consist of a bunch of traits, which you can get and set via this
  #class’ #[] and #[]= methods. The names of the traits which you may
  #set depend on the list of allowed traits for items in this category,
  #readable and modifyable through the Category class. To get the category
  #a specific entry belongs to, call #category on it.
  #
  #You can retrieve and modify the underlying list of Trait objects
  #directly by using #traits, but using the higher-level interface
  #provided by the #[] and #[]= methods is recommended.
  #
  #See the Category class for an example of usage.
  class Entry
    include DataMapper::Resource

    property :id, Serial
    belongs_to :category
    has n, :traits

    ##
    # :attr_accessor: category
    #The Category instance this entry belongs to.

    ##
    # :attr_reader: traits
    #The underlying list of Trait instances. DM query.

    #Read the trait of the specified name, which may be
    #a symbol or string.
    def [](name)
      trait = traits.first(:name => name.to_s)
      return trait.value if trait
      raise("Unknown trait #{trait}!")
    end

    #Write the trait of the specified name which must be
    #an trait name allowed for entries in this category
    #(see Category#traits). +name+ may be a symbol or a
    #string.
    def []=(name,  value)
      reload # Incorporate changes made to `traits' in the meantime

      if trait = traits.first(:name => name.to_s)
        # Overwrite existing trait
        trait.value = value
      else
        # Create new trait (name will be checked on saving)
        trait = Trait.new(:name => name, :value => value, :entry => self)
      end
      trait.save || raise(trait.errors.full_messages.first)
    end

  end

  #Internal class representing an trait name that entries
  #in a specific category may use. Also ensures that destroying
  #an object of this class removes all traits of its +name+
  #from the category things TraitName belongs to.
  class TraitName
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    belongs_to :category

    ##
    # :attr_accessor: name
    #The name of the allowed trait

    ##
    # :attr_accessor: category
    #The Category instance this TraitName belongs to.

    # Before destroying the trait name entirely, remove the
    # actual trait’s value from all the respective entries
    # in this category.
    before :destroy do
      category.entries.each{|e| e.traits.first(:name => name).destroy || raise("Error destroying trait #{name}!")}
    end

  end

  #Mostly internal class representing a single trait of
  #an Entry instance. Includes a validation ensuring that
  #the name given to this trait is in the list of allowed
  #traits for the category the entry holding this trait
  #belongs to.
  #
  #I aplogise for the name "trait", but sadly, both the name
  #"attribute" which I originally wanted to chose and the
  #more feasable alternative "property" are both already used
  #by DataMapper and therefore cannot be used as secure identifiers.
  class Trait
    include DataMapper::Resource

    property :id,    Serial
    property :name,  String, :default => ""
    property :value, String # TODO: Other type? YAMLise/Marshalise for correct Ruby type?

    belongs_to :entry

    validates_with_method :is_valid_trait

    ##
    # :attr_accessor: name
    #The name of this trait.

    ##
    # :attr_accessor: value
    #The value of this trait, as a string. This may change
    #in the future.

    ##
    # :attr_accessor: entry
    #The Entry instance this trait belongs to.

    private

    #Ensures that the name of this trait is allowed by the
    #category this trait’s entry belongs to.
    def is_valid_trait
      if entry.category.trait_names.any?{|an| an.name == name}
        true
      else
        [false, "Trait `#{name}' not defined for category `#{entry.category.name}'"]
      end
    end

  end

end
