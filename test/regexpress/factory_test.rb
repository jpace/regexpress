#!/usr/bin/ruby -w
# -*- ruby -*-

require 'test/unit'
require 'regexpress/factory'
require 'paramesan'

class RegexpFactoryTestCase < Test::Unit::TestCase
  include Paramesan
  
  param_test [
    [ "a\\z",     "a\\z"  ],
    [ "a\\.z",    "a.z"  ],
    [ "a\\.\\.z", "a..z" ],
    [ "a\\.z.*",  "a.z*" ],
    [ "a.z",      "a?z"  ],
    [ "a\\$",     "a$"   ],
    [ "a\\/z",    "a/z"  ],
    [ "a\\(z\\)", "a(z)" ],
  ].each do |exp, pat|
    assert_equal exp, RegexpFactory.new.from_shell_pattern(pat), "pat: #{pat}"
  end

  param_test [
    [ Regexp.new("a"), "a", Hash.new ],
    [ Regexp.new("b"), "b", Hash.new ],
  ].each do |exp, pat, args|
    assert_equal exp, RegexpFactory.new.create(pat, args), "pat: #{pat}; args: #{args}"
  end

  param_test [
    [ true,  "!/a"  ],
    [ false, "!a"   ],
    [ false, " !/a" ],
  ].each do |exp, pat|
    assert_equal exp, !!RegexpFactory.new.negative?(pat), "pat: #{pat}"
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
  ].each do |exp, pat|
    defparams = { multiline: false, ignorecase: false, extended: false, pattern: pat }
    params = defparams.merge exp
    result = RegexpFactory.new.pattern_to_flags pat
    assert_equal params, result, "pat: #{pat}; exp: #{exp}"
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
