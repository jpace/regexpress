#!/usr/bin/ruby -w
# -*- ruby -*-

# Negates the given expression.
class NegatedRegexp < Regexp
  def match str
    !super
  end
end

class RegexpFactory
  def initialize 
    @shell_patterns = Hash.new.tap do |pats|
      pats['*'] = '.*' 
      pats['?'] = '.'
      %w{ . $ / ( ) }.each do |ch|
        pats[ch] = "\\" + ch
      end
    end

    @negative_regexp = Regexp.new '^!/'

    @word_start_re = Regexp.new('^' +           # start of word
                                '[\[\(]*' +     # parentheses or captures, maybe
                                '(?:\\\w|\w|\.)') # literal \w, or what \w matches, or dot

    # general match for a, a*, a?, a{3,4}, etc.
    @word_end_re = Regexp.new('(?:\\\w|\w)\]*(?:\*|\.|\)|\+|\?|\{\d*,\d*\})?$')
  end
  
  def from_shell_pattern shpat
    re = Regexp.new '(\\\.)|(.)'    
    converted = ""
    shpat.gsub(re) do
      converted << ($1 || @shell_patterns[$2] || $2)
    end
    converted
  end

  # Creates a regular expression from a combination of a pattern and arguments:
  
  #   /foobar/     -- "foobar"
  #   /foo/bar/    -- "foo", then slash, then "bar"
  #   /foo\/bar/   -- same as above
  #   /foo/bar/i   -- same as above, case insensitive
  #   /foo/bari    -- "/foo/bari" exactly
  #   /foo/bar\/i  -- "/foo/bar/i" exactly
  #   foo/bar/     -- "foo/bar/" exactly
  #   foo/bar/     -- "foo/bar/" exactly
  
  def create pat, args = Hash.new
    negated    = args[:negated]
    ignorecase = args[:ignorecase]
    wholewords = args[:wholewords]
    wholelines = args[:wholelines]
    extended   = args[:extended]
    multiline  = args[:multiline]

    Regexp.new pat
  end

  def pattern_to_flags pattern
    flagre = Regexp.new '^\/(.*[^\\\])\/([mix]+)?'
    opts_to_chars = { multiline: 'm', ignorecase: 'i', extended: 'x' }

    flags = { pattern: pattern }.merge opts_to_chars.keys.collect { |x| [ x, false ] }.to_h
    
    if md = flagre.match(pattern)
      flags[:pattern] = md[1]
      
      if modifiers = md[2]
        opts_to_chars.each do |opt, ch|
          flags[opt] = modifiers.include? ch
        end
      end
    end
    
    flags
  end

  def negative? pat
    match? @negative_regexp, pat
  end

  def starts_on_word_boundary str
    match? @word_start_re, str
  end

  def ends_on_word_boundary str
    match? @word_end_re, str
  end

  # this seems to be added in 2.4
  def match? re, str
    re.match(str) != nil
  end
end

class Regexp
  WORD_START_RE = Regexp.new('^                 # start of word
                                [\[\(]*         # parentheses or captures, maybe
                                (?: \\\w | \\w) # literal \w, or what \w matches
                              ',
                             Regexp::EXTENDED)
  
  WORD_END_RE = Regexp.new('(?:                 # one of the following:
                                \\\w            #   - \w for regexp
                              |                 # 
                                \w              #   - a literal A-Z, a-z, 0-9, or _
                              |                 # 
                                (?:             #   - one of the following:
                                    \[[^\]]*    #         LB, with no RB until:
                                    (?:         #      - either of:
                                        \\w     #         - "\w"
                                      |         # 
                                        \w      #         - a literal A-Z, a-z, 0-9, or _
                                    )           #      
                                    [^\]]*\]    #      - anything (except RB) to the next RB
                                )               #
                            )                   #
                            (?:                 # optionally, one of the following:
                                \*              #   - "*"
                              |                 # 
                                \+              #   - "+"
                              |                 #
                                \?              #   - "?"
                              |                 #
                                \{\d*,\d*\}   #   - "{3,4}", "{,4}, "{,123}" (also matches the invalid {,})
                            )?                  #
                            $                   # fin
                           ', 
                           Regexp::EXTENDED)

  # Handles negation, whole words, and ignore case (Ruby no longer supports
  # Rexexp.new(/foo/i), as of 1.8).
  
  def self.create pat, args = Hash.new
    negated    = args[:negated]
    ignorecase = args[:ignorecase]
    wholewords = args[:wholewords]
    wholelines = args[:wholelines]
    extended   = args[:extended]
    multiline  = args[:multiline]

    pattern    = pat.dup
    
    # we handle a ridiculous number of possibilities here:
    #     /foobar/     -- "foobar"
    #     /foo/bar/    -- "foo", then slash, then "bar"
    #     /foo\/bar/   -- same as above
    #     /foo/bar/i   -- same as above, case insensitive
    #     /foo/bari    -- "/foo/bari" exactly
    #     /foo/bar\/i  -- "/foo/bar/i" exactly
    #     foo/bar/     -- "foo/bar/" exactly
    #     foo/bar/     -- "foo/bar/" exactly

    if pattern.sub!(%r{ ^ !(?=/) }x, "")
      negated = true
    end

    if pattern.sub!(%r{ ^ \/ (.*[^\\]) \/ ([mix]+) $ }x) { $1 }
      modifiers  = $2
      
      multiline  ||= modifiers.index('m')
      ignorecase ||= modifiers.index('i')
      extended   ||= modifiers.index('x')
    else
      pattern.sub!(%r{ ^\/ (.*[^\\]) \/ $ }x) { $1 }
    end

    if wholewords
      # sanity check:

      errs = [
        [ WORD_START_RE, "start" ],
        [ WORD_END_RE,   "end"   ]
      ].collect do |ary|
        re, err = *ary
        re.match(pattern) ? nil : err
      end.compact
      
      if errs.length > 0
        raise RuntimeError.new("pattern '#{pattern}' does not " + errs.join(" and ") + " on a word boundary")
      end
      pattern = '\b' + pattern + '\b'
    elsif wholelines
      pattern = '^'  + pattern + '$'        # ' for emacs
    end
    
    reclass = negated ? NegatedRegexp : Regexp

    flags = [
      [ ignorecase, Regexp::IGNORECASE ],
      [ extended,   Regexp::EXTENDED   ],
      [ multiline,  Regexp::MULTILINE  ]
    ].inject(0) do |tot, ary|
      val, flag = *ary
      tot | (val ? flag : 0)
    end
    
    reclass.new pattern, flags
  end

  def self.matches_word_start? pat
    WORD_START_RE.match pat
  end

  def self.matches_word_end? pat
    WORD_END_RE.match pat
  end

  # applies Perl-style substitution (s/foo/bar/).
  def self.perl_subst pat
  end
end
