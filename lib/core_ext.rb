class Module
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?

    with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"

    alias_method without_method, target
    alias_method target, with_method

    case
      when public_method_defined?(without_method)
        public target
      when protected_method_defined?(without_method)
        protected target
      when private_method_defined?(without_method)
        private target
    end
  end
end

class Range
  def start
    min || self.begin
  end

  def finish
    max || self.end
  end

  def distance
    (finish - start).abs
  end

  # Breaks a range over a number of steps equal to the number of animation
  # frames contained in the specified seconds. To avoid rounding errors, the
  # values are yielded as Rational numbers, rather than as integers or floats.
  #
  # It differs from #step in that:
  # * the beginning and end of the range are guarranteed to be returned, even
  #   if the size of the steps needs to be munged
  # * the argument is in seconds, rather than the size of the steps
  # * it works on descending and negative ranges as well
  #
  #  (0..10).over(1).to_a # => [0, (5/27), (10/27), (5/9), (20/27)... (10/1)]
  #  (20..0).over(0.1).to_a # => [20, (140/9), (100/9), (20/3), (20/9), (0/1)]
  def over seconds
    total_frames = seconds.to_frames
    finish = self.finish.to_r
    start = self.start.to_r
    distance = (finish - start).abs
    value = start

    Enumerator.new do |yielder|
      loop do
        yielder.yield value
        break if value == finish # this is a post-conditional loop

        remaining_distance = distance - (start - value).abs
        delta = Rational(remaining_distance, (total_frames -= 1).greater_of(1))
        delta = -delta if start > finish
        value += delta
      end
    end
  end
end

class Numeric
  # Assume the current number is frames, and convert it to an equivalent
  # number of seconds.
  def frames
    to_f * Rdmx::Animation.frame_duration
  end
  alias_method :frame, :frames

  # Assume the current number is minutes, and convert it to an equivalent
  # number of seconds.
  def minutes
    self * 60
  end
  alias_method :minute, :minutes

  # Assume the current number is seconds, and convert it to an equivalent
  # number of seconds. Ie. do nothing.
  def seconds
    self
  end
  alias_method :second, :seconds

  # Assume the current number is milliseconds, and convert it to an equivalent
  # number of seconds.
  def milliseconds
    to_f / 1000.0
  end
  alias_method :ms, :milliseconds

  # Assume the current number is seconds, and convert it to an equivalent
  # number of frames.
  def to_frames
    self * Rdmx::Animation.fps
  end

  # Enumerable#min is slow.
  def lesser_of other
    other < self ? other : self
  end

  # Enumerable#max is slow.
  def greater_of other
    other > self ? other : self
  end
end

class Fifo < Array
  attr_accessor :max_size

  def initialize max_size
    self.max_size = max_size
  end

  def full?
    size == max_size
  end

  def push value
    super value
    shift if size > max_size
  end
end
