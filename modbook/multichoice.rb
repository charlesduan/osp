#!/usr/bin/env ruby



class ChoiceText

  PAREN_LETTER = /\((.)\)/
  TRAIL_LIST = /\A(?:|(?:,\s+\(.\))+,?)\s+(and|or)\s+\(.\)/i

  def initialize(text)

    #
    # @parts will be a list of the parsed text. Its elements will be strings and
    # ChoiceList objects, which if concatenated will reconstruct the
    # text.
    #
    @parts = []

    #
    # Split off parenthesized choice names
    #
    while (m = text.match(PAREN_LETTER))
      @parts.push(m.pre_match) if m.pre_match != ''
      letters = [ m[1] ]
      conjunction = 'and'
      text = m.post_match

      if (m = text.match(TRAIL_LIST))
        # The trail list didn't match. Add the matched choice letter to the
        # list.
        conjunction = m[1]
        letters.push(*m[0].scan(PAREN_LETTER).flatten)
        text = m.post_match
      end

      @parts.push(ChoiceList.new(conjunction, *letters))
    end

    # Add any remaining text to the list
    @parts.push(text)
  end


  #
  # Returns a list of all the choices identified in this text.
  #
  def choices
    @parts.select { |x| x.is_a?(ChoiceList) }.map(&:choices).flatten.uniq
  end

  def has_choices?
    @parts.any? { |p| p.is_a?(ChoiceList) }
  end

  def to_s(random_map = nil)
    @parts.map { |x|
      x.is_a?(ChoiceList) ? x.to_s(random_map) : x
    }.join()
  end




  #
  # Represents a list of several choices joined by a conjunction.
  #
  class ChoiceList
    def initialize(conjunction, *choices)
      @conjunction = conjunction
      @choices = choices
      raise "Must provide choices" if @choices.empty?
      raise "Invalid choices #{choices.inspect}" unless @choices.all? { |c|
        c.is_a?(String) && c.length == 1
      }
    end
    attr_reader :conjunction, :choices

    #
    # Formats the list of choices. The list is mapped according to the
    # random_map if given, and is sorted and parenthesized.
    #
    def to_s(random_map = nil)
      if random_map
        c = @choices.map { |x|
          raise "No mapping for choice #{x}" unless random_map.include?(x)
          random_map[x]
        }.sort
      else
        c = @choices.sort
      end
      c = c.map { |x| "(#{x})" }
      case c.length
      when 1 then c.first
      when 2 then "#{c.first} #@conjunction #{c.last}"
      else "#{c[0..-2].join(', ')}, #@conjunction #{c.last}"
      end
    end
  end


end


class MultiChoice

  FIRST_CHOICE = "A"

  def initialize
    @choices = {}
  end

  #
  # Ensures that every choice is a single letter.
  #
  def check_choice_name(choice)
    return if choice.is_a?(String) && choice.length == 1
    raise TypeError, "Invalid choice name #{choice}"
  end


  #
  # Setter for the question's answer.
  #
  def answer=(a)
    @answer = ChoiceText::ChoiceList.new(
      "and", *a.split(/[.,\s]+/) - %w(and AND)
    )
  end
  def answer
    return @answer.to_s(@random_map)
  end

  #
  # Setter for the question's explanation.
  #
  def explanation=(e)
    @explanation = ChoiceText.new(e)
  end
  def explanation
    return @explanation.to_s(@random_map)
  end

  #
  # Setter for the question's text.
  #
  def question=(q)
    @question = ChoiceText.new(q)
  end
  def question
    return @question.to_s(@random_map)
  end


  #
  # Sets the text for the given choice.
  #
  def []=(choice, value)
    check_choice_name(choice)
    return @choices[choice] = ChoiceText.new(value)
  end

  ABOVE_REFERENCE = /(all|any|some|none|each)\s+of\s+the\s+above/i

  #
  # Constructs the random map for this question. The random map will rearrange
  # all choices that are not order-dependent, namely choices that do not
  # cross-reference other choices.
  #
  def randomize
    random_elts = {}
    xref_elts = {}

    #
    # Categorize choices into basic randomizable choices, choices with
    # cross-references, and "X of the above" choices.
    #
    @choices.each do |choice, value|
      if value.has_choices? or ABOVE_REFERENCE.match(value.to_s)
        xref_elts[choice] = value
        missing_choices = value.choices - random_elts.keys
        unless missing_choices.empty?
          warn(
            "Choice \"#{value}\" references choices " \
            "#{missing_choices.join(", ")} that did not precede it"
          )
        end

      elsif !xref_elts.empty?
        # This is a basic, non-cross-reference choice but it follows a
        # cross-reference choice. It cannot be automatically moved because that
        # might change the meaning of any "X of the above" choices. To keep it
        # in place, the choice is treated as if it is a cross-reference choice.
        #
        # An alternative option would be to replace the "X of the above" choices
        # with an explicit list.
        warn(
          "A non-cross-reference choice follows cross-reference choices. " \
          "Consider rearranging."
        )
        xref_elts[choice] = value
      else
        random_elts[choice] = value
      end
    end

    @random_map = {}
    letter = FIRST_CHOICE
    (random_elts.keys.shuffle + xref_elts.keys).each do |choice|
      @random_map[choice] = letter
      letter = letter.succ
    end
    return @random_map
  end

  #
  # Iterates through the choices.
  def each
    if @random_map
      @random_map.to_a.map(&:reverse).sort.each do |new_choice, orig_choice|
        yield(new_choice, @choices[orig_choice].to_s(@random_map))
      end
    else
      @choices.keys.sort.each do |choice|
        yield(choice, @choices[choice])
      end
    end
  end
end


def line_break(text, len: 80, prefix: '', preserve_lines: false)
	res = ''
	strlen = len - prefix.length
	text = text.gsub("\n", " ") unless preserve_lines
	while text.length > strlen
		if text =~ /\A[^\n]{0,#{strlen}}\s+/
			res << prefix + $&.rstrip + "\n"
			text = $'
		else
			res << prefix + text[0, strlen]
			text = text[strlen..-1]
		end
	end
	res << prefix + text
	return res
end


def write_q(question, io)
  return unless question
  question.randomize
  raise "No file specified for writing questions" if io.nil?

  io.write("\\multichoiceq{%\n")
  io.write(line_break(question.question + "%", prefix: '    ') + "\n")
  io.write("}{%\n")
  question.each do |choice, text|
    io.write(line_break(
      "\\multichoiceitem{#{choice}}{#{text}}%", prefix: '    '
    ) + "\n")
  end
  io.write("}{#{question.answer}}{%\n")
  io.write(line_break(question.explanation + "%", prefix: '    ') + "\n")
  io.write("}\n\n")
end

parts = []
ARGF.read.split(/\n\n+/).each do |para|
  para = para.gsub(/\s+/, " ")
  if (m = /\A(\w+): /.match(para))
    parts.push([ m[1], m.post_match ])
  else
    parts.last += "\n\n" + para
  end
end

out_io = STDOUT
cur_q = nil
parts.each do |type, text|
  case type.downcase
  when 'file'
#      write_q(cur_q, out_io)
#      out_io.close if out_io
#      if File.exist(text)
#        warn("File #{text} exists. Overwrite?")
#        exit unless STDIN.gets =~ /^y/i
#      end
#      out_io = open(text, 'w')

  when 'question'
    write_q(cur_q, out_io)
    cur_q = MultiChoice.new
    cur_q.question = text

  when 'answer'
    if (m = /\. /.match(text))
      cur_q.answer = m.pre_match
      cur_q.explanation = m.post_match
    else
      cur_q.answer = text
    end

  when /\A.\z/
    cur_q[type] = text

  else
    raise "Unexpected line #{type}: #{text}"
  end

end
write_q(cur_q, out_io)
out_io.close


