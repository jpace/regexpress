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
    [ Regexp.new("c"), "c", Hash.new ],
    [ Regexp.new("c", Regexp::IGNORECASE), "/c/i", Hash.new ],
    [ Regexp.new("c/i"), "c/i", Hash.new ],
    [ Regexp.new("\\bdef\\b"), "def", { wholewords: true } ],
    [ Regexp.new("^def$"), "def", { wholelines: true } ],
    [ Regexp.new("\\bdef\\b"), "def", { wholewords: true, wholelines: true } ],
  ] do |exp, pat, args|
    assert_equal exp, RegexpFactory.new.create(pat, args), "pat: #{pat}; args: #{args}"
  end

  def test_negated
    re = RegexpFactory.new.create "def", negated: true
    assert_kind_of NegatedRegexp, re
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

  def self.check_whole_word_data
    Array.new.tap do |params|
      params.concat [ 'a',   'ab'   ].collect { |pat| [ true,  true,  pat ] }
      params.concat [ ' a',  ' ab'  ].collect { |pat| [ false, true,  pat ] }
      params.concat [ 'a ',  'ab '  ].collect { |pat| [ true,  false, pat ] }
      params.concat [ ' a ', ' ab ' ].collect { |pat| [ false, false, pat ] }
    end
  end

  param_test check_whole_word_data do |exp_starts, exp_ends, pat|
    check = RegexpFactory.new.check_whole_word pat

    msg = "pat: #{pat}"
    assert_equal exp_starts, check[:starts], msg
    assert_equal exp_ends,   check[:ends],   msg
  end

  param_test [
    [ 0, Hash.new ],
 
    [ Regexp::IGNORECASE, { ignorecase: true } ],
    [ 0,                  { ignorecase: false } ],
    [ Regexp::MULTILINE,  { multiline: true } ],
    [ 0,                  { multiline: false } ],
    [ Regexp::EXTENDED,   { extended: true } ],
    [ Regexp::IGNORECASE | Regexp::EXTENDED,   { ignorecase: true, extended: true } ],
  ] do |exp, flags|
    arg = RegexpFactory.new.flags_to_arg flags
    assert_equal exp, arg, "flags: #{flags}"
  end
end
