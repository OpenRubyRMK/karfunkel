# -*- coding: utf-8 -*-
require_relative "helpers"

class MapTest < Test::Unit::TestCase
  include OpenRubyRMK
  include OpenRubyRMK::Karfunkel::Plugin::Base

  def setup
    @project = Project.new(Dir.mktmpdir)
  end

  def teardown
    @project.delete!
  end

  def test_creation
    map = Map.new(@project)
    assert(map.root?, "Didn't recognise a map without a parent as a root map.")
    assert_equal(1, map.id)
    assert_equal("Map_1", map.name)
    assert_empty(map.children)

    map = Map.new(@project, "foo-map")
    assert_equal(2, map.id)
    assert_equal("foo-map", map.name)
  end

  def test_copying
    map1 = Map.new(@project, "foo-map")
    map2 = map1.dup
    refute_equal(map1.id, map2.id)
    refute_equal(map1, map2) # Different IDs!
    assert_equal(map1.name, map2.name)

    map3 = Map.new(@project, "bar-map")
    map3.parent = map1
    map4 = map1.dup
    refute_empty(map1.children)
    assert_empty(map4.children) # Children are not copied!

    assert_equal(map1, map1)
    assert_equal(map3, map3)
  end

  def test_children
    # root_map
    #   |
    # child_map
    root_map         = Map.new(@project)
    child_map        = Map.new(@project)
    child_map.parent = root_map

    # Test root and child map know one another
    assert_equal(1, root_map.children.count)
    assert_equal(root_map, child_map.parent)
    assert_empty(child_map.children)
    assert(root_map.has_child?(child_map),    "Child not recognised!")
    assert(root_map.has_child?(child_map.id), "Child ID not recognised!")

    # root_map
    #   |
    # child_map
    #   |
    # grandchild_map
    grandchild_map = Map.new(@project)
    grandchild_map.parent = child_map

    # Check who knows whom
    refute(root_map.has_child?(grandchild_map),  "Grandchild recognised!")
    assert(child_map.has_child?(grandchild_map), "Child not recognised!")
    assert(root_map.ancestor?(grandchild_map),   "Didn't recognise itself as an ancestor of a grandchild!")

    # root_map
    #   |
    # child_map
    #   |
    # grandchild_map
    #   |
    # grandgrandchild_map
    grandgrandchild_map = Map.new(@project)
    grandgrandchild_map.parent = grandchild_map

    # Delete child_map, preserving the children:
    #
    # root_map
    #   |
    # grandchild_map
    #   |
    # grandgrandchild_map
    grandchild_map.parent = root_map
    child_map.delete
    assert_equal(1, root_map.children.count)
    assert_equal(grandchild_map, root_map.children.first)
    assert_equal(root_map, grandchild_map.parent)

    # Now delete grandchild_map plus children.
    #
    # root_map
    #   |
    # (nothing)
    grandchild_map.delete
    assert_empty(root_map.children)
  end

  def test_reparenting
    # root_map
    #    |
    #    +-------------+
    #    |             |
    # child_map   child2_map
    root_map   = Map.new(@project)
    child_map  = Map.new(@project)
    child2_map = Map.new(@project)
    child_map.parent  = root_map
    child2_map.parent = root_map
    assert_equal(2, root_map.children.count)

    # root_map
    #   |
    # child2_map
    #   |
    # child_map
    child_map.parent = child2_map
    assert_equal(1, child2_map.children.count)
    assert_equal(1, root_map.children.count)
    assert_equal(child2_map, root_map.children.first)
    assert_equal(child2_map, child_map.parent)
    assert_equal(child_map, child2_map.children.first)
    assert_equal(root_map, child_map.parent.parent)
  end

  def test_saving
    map = Map.new(@project) # Implicit ID 1
    assert_equal(@project.paths.maps_dir.join("0001.tmx"), map.path)
    refute(File.read(@project.paths.maps_dir.join("0001.tmx")).length.zero?, "Map file has zero length.")
  end

end
