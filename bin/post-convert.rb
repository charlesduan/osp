#!/usr/bin/env ruby
#
# Copyright 2024 Charles Duan.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


WORD_RE = /[A-Z][\w.',-]*|and|\\&|of/
CASE_RE = /((?:#{WORD_RE} )+v\.(?: #{WORD_RE})+), (\d+)/

def italicize_cases(s)

  pre = ''

  while (m = CASE_RE.match(s))
    pre += m.pre_match
    s = m.post_match
    if m.pre_match =~ /\{[^\}]*\z/
      pre += m[0]
    else
      pre += "\\emph{#{m[1]}}, #{m[2]}"
    end
  end
  return pre + s
end

JUDGE_RE = /
  (?:(?:Mr\.\s+)?(?:Chief\s+)?(?:Justice|Judge))
  |[^abd-z]+,\s+(?:[A-Z.]*J\.|(?:\w+\s+)?Judges?)
/x
OPINING_RE = /concurring|dissenting|delivered (?:the|an) opinion/

def identify_opinion(s)
  return s unless s =~ /^#{JUDGE_RE}(?:\.?\s*$|.*#{OPINING_RE})/
  return "\\opinion " + s.gsub(/\w[A-Z]{3,20}\w/) { |m|
    "\\textsc{#{m.capitalize}}"
  }
end

class EnvManager
  def initialize
    @lines = []
    @replacements = {}
  end

  def add(line)
    if line =~ /\A\\begin{(\w+)}\Z/
      env = $1

      if env == 'quote'
        @lines.pop while @lines.last == "\n"
      end

      (@lines.count - 1).downto(0) do |i|
        if @lines[i] == "\\end{#{env}}\n"
          @lines[i] = "\n"
          make_begin_quotation if env == 'quote'
          return
        elsif @lines[i] != "\n"
          break
        end
      end
    elsif line =~ /^Notes and Questions$/
      @replacements["\\begin{enumerate}\n"] = "\\begin{questions}\n"
      return
    end

    line = @replacements.delete(line) if @replacements[line]
    @lines.push(line)
  end

  def make_begin_quotation
    @replacements["\\end{quote}\n"] = "\\end{quotation}\n"

    (@lines.count - 1).downto(0) do |i|
      if @lines[i] == "\\begin{quote}\n"
        @lines[i] = "\\begin{quotation}\n"
        break
      end
    end
  end

  def write
    @lines.each do |line|
      puts line_break(line)
    end
  end

  def line_break(s)
    pre = ''
    while s =~ /^[^\n]{80}/
      if s =~ /^([^\n]{1,80})\s+/
        pre += $` + $1 + "\n"
        s = $'
      elsif s =~ /\s+/
        pre += $` + "\n"
        s = $'
      else
        break
      end
    end
    return pre + s
  end

end


after_reading = false
accumulator = ''
urls = {}

env_mgr = EnvManager.new

ARGF.each do |line|

  if line =~ /\{[^}]*\z/
    accumulator += line.strip + ' '
    next
  elsif !accumulator.empty?
    accumulator += line.strip
    if accumulator.count('{') > accumulator.count('}')
      accumulator += ' '
      next
    else
      line = accumulator + "\n"
      accumulator = ''
    end
  end

  # Links
  line.gsub!(/\\href\{([^}]*)\}\{([^}]*)\}/) {
    url = ", \\url{#$1}"
    if urls[url]
      url = ''
    else
      urls[url] = 1
    end
    "#$2#{url}"
  }

  if line.start_with?("\\reading{")
    after_reading = true
  elsif after_reading
    unless line == "\n" || line.start_with?("\\readingcite{")
      after_reading = false
    end
  else
    line.gsub!("\\readingcite{", "\\readinghead{")
  end

  line.gsub!(/\\clearpage\s*/, '')
  line.gsub!(/\\setcounter\{page\}\{\d+\}\s*/, '')

  line.gsub!(/\s+}/, "} ") # Trailing spaces in macro args
  line.gsub!(/([,;:])}/, "}\\1") # Trailing comma in macro args
  line.gsub!(/\\footnote{\s+/, "\\footnote{") # Leading space in footnote

  # Empty macros
  line.gsub!(/\\text(?:it|bf|sc|style\w+)\{([.\s]*)\}/, "\\1")

  # Blanks at start of macros
  line.gsub!(/\\text(it|bf|sc|style\w+)\{\s+/, " \\text\\1{")

  # Optional arg in sections
  if line =~ /(\\(?:sub)*section)\[.*?\]{(?:\w\.[\\ ]* )?/
      line = "\n\n#$1{#$'\n"
  end

  # Superscript
  line.gsub!(/\\textsuperscript\{(\w+)\}/, "\\1")

  line.gsub!("{\\S} ", "\\S~")
  line.gsub!("'{}''", "'\\,''")
  line.gsub!("``{}`", "``\\,`")
  line.gsub!(",{}''", ",''")
  line.gsub!(/^{}``/, "``")

  quote_open = false
  line.gsub!("{\\textquotedbl}") { |m|
    quote_open = !quote_open
    quote_open ? "``" : "''"
  }

  line.gsub!(/ ---? /, "---")
  line.gsub!(/\}\{\}(['-])/, "}\\1")
  line.gsub!(/\s+\{\}``/, " ``")

  # Ellipses
  line.gsub!(" {\\dots}.", "\\ldots.")
  line.gsub!(".{\\dots} ", ".\\ldots ")
  line.gsub!(/\{\\dots\}$/, "\\ldots")
  line.gsub!(/^[.\s]*\{\\dots\}[.\s]*/, "\\ldots ")
  line.gsub!(". {\\dots} ", ".\\ldots ")
  line.gsub!(/\s*\{\\dots\}\s*/, "\\ldots ")
  line.gsub!("....", "\\ldots.")
  line.gsub!(/^\.\.\.\s*/, "\\ldots ")
  line.gsub!(/\s*\.\.\.$/, "\\ldots")
  line.gsub!(" ... ", "\\ldots ")
  line.gsub!("  ", " ")

  # Bold run-in text
  line.sub!(/\A\\textbf\{([^}]+)\.?\}\.?\s+/, "\\paragraph{\\1}\n")

  # Justices and cases
  line = identify_opinion(line)
  line = italicize_cases(line)

  if line =~ /\\(textsc|readinghead)\{([^a-z]+)\}/
    pre, text, post = "#$`\\#$1{", $2, "}#$'"
    unless text =~ /\A[IVXLC.]+\z/
      line = pre + text.split(/\s+/).map(&:capitalize).join(" ") + post
    end
  end

  if line =~ /
    \A\{
    (?:\\centering|\\bfseries|\\itshape)+\s*
    (.*?)
    (?:\s*\\par\s*)?
    \}\Z
    /x
    line = "\n#$1\n"
  end

  line.gsub!(/\\includegraphics\[.*?\]\{(.*?)\}/, "\\heregraphic{\\1}\n")

  # Footnotes in text
  while line =~ /\\footnote\{\\textstyleFootnoteSymbol\{(\d+)\}\s*/
    line = "#$`\\readingfootnote{#$1}{" + $'.gsub("}#$1", "}")
  end

  env_mgr.add(line)
end

unless accumulator.empty?
  warn("Unclosed brace somewhere, please check")
  env_mgr.add(accumulator)
end

env_mgr.write
