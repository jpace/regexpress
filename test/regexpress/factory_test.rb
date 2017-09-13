#!/usr/bin/ruby -w
# -*- ruby -*-

require 'test/unit'
require 'regexpress/factory'
require 'paramesan'

class RegexpFactoryTestCase < Test::Unit::TestCase
  include Paramesan
  
  param_test [
    [ "a\\z",     "a\\z" ],
    [ "a\\.z",    "a.z"  ],
    [ "a\\.\\.z", "a..z" ],
    [ "a\\.z.*",  "a.z*" ],
    [ "a.z",      "a?z"  ],
    [ "a\\$",     "a$"   ],
    [ "a\\/z",    "a/z"  ],
    [ "a\\(z\\)", "a(z)" ],
  ] do |exp, pat|
    assert_equal exp, RegexpFactory.new.from_shell_pattern(pat), "pat: #{pat}"
  end

  param_test [
    [ Regexp.new("a"), "a", Hash.new ],
    [ Regexp.new("b"), "b", Hash.new ],
  ] do |exp, pat, args|
    assert_equal exp, RegexpFactory.new.create(pat, args), "pat: #{pat}; args: #{args}"
  end

  param_test [
    [ true,  "!/a"  ],
    [ false, "!a"   ],
    [ false, " !/a" ],
  ] do |exp, pat|
    assert_equal exp, RegexpFactory.new.negative?(pat), "pat: #{pat}"
  end

  param_test [
    [ Hash.new, "a" ],
    [ Hash.new, "a/" ],
    [ Hash.new, "/a" ],
    [ { pattern: "a" }, "/a/" ],
    [ { extended: true, pattern: "a" }, "/a/x" ],
    [ { ignorecase: true, pattern: "a" }, "/a/i" ],
    [ { multiline: true, pattern: "a" }, "/a/m" ],
    [ { multiline: true, ignorecase: true, pattern: "a" }, "/a/mi" ],
    [ { multiline: true, ignorecase: true, pattern: "a" }, "/a/im" ],
    [ { extended: true, multiline: true, ignorecase: true, pattern: "a" }, "/a/xim" ],
  ] do |exp, pat|
    defparams = { multiline: false, ignorecase: false, extended: false, pattern: pat }
    params = defparams.merge exp
    result = RegexpFactory.new.pattern_to_flags pat
    assert_equal params, result, "pat: #{pat}; exp: #{exp}"
  end

  def self.starts_on_word_boundary_data
    Array.new.tap do |params|
      trues = [ 'a', '.', '(a', '([a', '[a', '[(a', '\w' ]
      params.concat trues.collect { |str| [ true,  str ] }

      falses = [ '!a', ' a' ]
      params.concat falses.collect { |str| [ false,  str ] }
    end
  end

  param_test starts_on_word_boundary_data do |exp, pat|
    matches = RegexpFactory.new.starts_on_word_boundary pat
    assert_equal exp, matches, "pat: #{pat}"
  end

  def self.ends_on_word_boundary_data
    Array.new.tap do |params|
      trues = [ 'a', 'w', '\w', '\\w', 'a*', 'a+', 'a?', 'a.', 'a{1,3}', 'a[bc', 'a[b-d', 'a[b-d+', 'a[b*', 'a)' ]
      params.concat trues.collect { |str| [ true,  str ] }
      
      falses = [ 'a[b-]', 'a!' ]
      params.concat falses.collect { |str| [ false,  str ] }
    end
  end

  param_test ends_on_word_boundary_data do |exp, pat|
    matches = RegexpFactory.new.ends_on_word_boundary pat
    assert_equal exp, matches, "pat: #{pat}"
  end  
end

# class RegexpTestCase < Test::Unit::TestCase
#   include Paramesan
  
#   def test_negated
#     assert NegatedRegexp.new("a[b-z]").match("aa")
#     assert NegatedRegexp.new(".+").match("")
#   end
  
#   def test_invalid_whole_word
#     assert_raises(RuntimeError) do
#       Regexp.create ':abc', wholewords: true
#     end
#   end
# end
