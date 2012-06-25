require_relative "helpers"

class CategoryTest < Test::Unit::TestCase
  include OpenRubyRMK
  include OpenRubyRMK::Karfunkel::Plugin::Base

  def test_creation
    cat = Category.new("stuff")
    assert_equal("stuff", cat.name)
    assert_empty(cat.allowed_attributes)
    assert_empty(cat.entries)
  end

  def test_load_and_save
    items = Category.new("items")
    items.add_attribute("name")
    items.add_attribute("type")

    item = Category::Entry.new(items)
    item[:name] = "Cool thing"
    item[:type] = "ice"
    items << item

    item = Category::Entry.new(items)
    item[:name] = "Hot thing"
    item[:type] = "fire"
    items << item

    Dir.mktmpdir do |tmpdir|
      path = "#{tmpdir}/test.xml"
      items.save(path)
      assert(File.file?(path), "Didn't save into #{path}")

      items = Category.load(path)
      assert_equal(2, items.entries.count)
      assert_equal("Cool thing", items.entries.first[:name])
      assert_equal("fire", items.entries.last[:type])
    end
  end

  def test_add_and_delete_attributes
    cat = Category.new("stuff")
    cat.add_attribute("name")
    cat.add_attribute("usability")

    assert_equal(2, cat.allowed_attributes.count)
    assert_includes(cat.allowed_attributes, "name")
    assert_includes(cat.allowed_attributes, "usability")
    
    item = Category::Entry.new(cat)
    item[:name] = "Foo"
    item[:usability] = "Bar"
    cat.add_attribute("grade_of_nonsense")
    assert_equal("", item[:grade_of_nonsense])

    item[:grade_of_nonsense] = "100%"
    cat.delete_attribute(:grade_of_nonsense)
    assert_raises(Category::UnknownAttribute){item[:grade_of_nonsense]}

    cat.delete_attribute("usability")
    refute_includes(cat.allowed_attributes, "usability")
  end

  def test_entries
    cat = Category.new("stuff")
    cat.add_attribute("foo")
    cat.add_attribute("bar")

    entry = Category::Entry.new(cat)
    entry["foo"] = "Bar"

    assert_equal(cat, entry.category)
    assert_equal("Bar", entry[:foo])
    assert_equal("Bar", entry["foo"])
    assert_raises(Category::UnknownAttribute){entry["baz"]}
    assert_raises(Category::UnknownAttribute){entry["baz"] = "blubb"}

    # Add an entry AFTER the call to Entry#initialize has
    # happened, i.e. the entry has no information that
    # we have a new attribute yet. It has to consult the
    # Category object again.
    cat.add_attribute("baz")
    entry["baz"] = "foobar" # Should not error out with UnknownAttribute anymore
  end

end
