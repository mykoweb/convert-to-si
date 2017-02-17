require 'sinatra'

class Converter
  attr_reader :units, :unit_name, :mult_factor

  def initialize(units = '')
    @units     = units.strip.downcase
    @unit_name = @units.dup

    # Convert units to the SI unit names
    conversion_factors.each do |k,v|
      @unit_name.gsub!(/\b#{k}\b/, v.last)
    end

    # Generate the multiplication factor
    @mult_factor = convert
  end

  private

  def convert
    fail MalformedParenthesesError unless wellformed_parens? units.split('')

    convert_helper units
  end

  def convert_helper(units = '')
    return 1.0 if units.empty?
    if base_operand? units
      fail MalformedUnitError unless conversion_factors[units]

      return conversion_factors[units].first
    end

    result = 1.0

    if units_enclosed_in_parens? units
      result *= convert_helper rm_first_and_last_char units
    else
      operator = ''
      operands = split_on_operators units
      result *= operands.inject(1.0) do |res, operand|
        if operator == ''
          res = partial_result(operand)
        elsif operator == '*'
          res *= partial_result(operand)
        else # division
          res = res / partial_result(operand)
        end

        operator = operand[-1] if operand?(operand[-1])

        res
      end
    end

    result
  end

  def partial_result(operand)
    if units_enclosed_in_parens? operand
      convert_helper rm_first_and_last_char(operand)
    else
      fail MalformedUnitError unless conversion_factors[rm_trailing_operand(operand)]

      conversion_factors[rm_trailing_operand(operand)].first
    end
  end

  # #base_operand? returns true if the string does not contain '(', ')', '/',
  # or '*'.
  def base_operand?(str)
    str = str.join if str.is_a? Array

    (str =~ /[()\*\/]/).nil?
  end

  def operand?(char)
    char == '/' || char == '*'
  end

  # #split_on_operator splits a string on '/' or '*' but ignores the characters
  # that are within parentheses. It also keeps the delimiter in the result.
  #
  # For example,
  # > split_on_operators('degree*min/(day*day)')
  # => ["degree*", "min/", "(day*day)"]
  def split_on_operators(str)
    str = str.join if str.is_a? Array
    return [str] if base_operand?(str)

    results      = []
    follower_ptr = 0
    parens_stack = []
    (0..(str.length-1)).each do |leader_ptr|
      if leader_ptr == str.length-1
        results << str[follower_ptr..leader_ptr]
      elsif str[leader_ptr] == '('
        parens_stack << '('
      elsif str[leader_ptr] == ')'
        parens_stack.pop
      elsif operand?(str[leader_ptr]) && parens_stack.empty?
        results << str[follower_ptr..leader_ptr]
        follower_ptr = leader_ptr + 1
      end
    end

    results
  end

  # #units_enclosed_in_parens? takes in a string and returns a boolean. It
  # tells us whether the string was enclosed in parentheses or not.
  def units_enclosed_in_parens?(units)
    units_arr = units.split ''
    units_arr = rm_trailing_operand units_arr

    return false if units_arr.length < 2
    return false unless units_arr.first == '(' && units_arr.last == ')'
    return true if units_arr.length < 3 # units is '()'

    return wellformed_parens? units_arr[1..-2]
  end

  def rm_first_and_last_char(str)
    str = rm_trailing_operand str
    str[1..-2]
  end

  def rm_trailing_operand(str)
    return str[0..-2] if operand?(str[-1])
    str
  end

  # #wellformed_parens? returns a boolean signifying whether the string array
  # had well-formed parentheses. A string that does not have well-formed
  # parentheses would be any of ')(', '(((', or '(()', for example.
  #
  # An example of a string with well-formed parentheses is '()()' or '((()))()'
  def wellformed_parens?(units_arr = [])
    parens_stack = []

    units_arr.each do |char|
      if char == '('
        parens_stack << char
      elsif char == ')'
        return false if parens_stack.empty?
        return false if parens_stack.last != '('
        parens_stack.pop
      end
    end

    return parens_stack.empty?
  end

  def conversion_factors
    @_conversion_factors ||= {
      'minute'  => [60, 's'],
      'min'     => [60, 's'],
      'hour'    => [3600, 's'],
      'h'       => [3600, 's'],
      'day'     => [86400, 's'],
      'd'       => [86400, 's'],
      'degree'  => [Math::PI/180, 'rad'],
      '°'       => [Math::PI/180, 'rad'],
      '‘'       => [Math::PI/10800, 'rad'],
      'second'  => [Math::PI/648000, 'rad'],
      '“'       => [Math::PI/648000, 'rad'],
      'hectare' => [10000, 'm2'],
      'ha'      => [10000, 'm2'],
      'litre'   => [0.001, 'm3'],
      'l'       => [0.001, 'm3'],
      'tonne'   => [1000, 'kg'],
      't'       => [1000, 'kg']
    }
  end
end
