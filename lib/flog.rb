require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'unified_ruby'

$a ||= false # report all methods, not just 60%
$m ||= false # real methods only (no global scope)
$s ||= false # summary only
$v ||= false # verbose, print methods as processed

class Flog < SexpProcessor
  VERSION = '1.2.0'

  include UnifiedRuby

  THRESHOLD = $a ? 1.0 : 0.60
  SCORES = Hash.new(1)
  BRANCHING = [ :and, :case, :else, :if, :or, :rescue, :until, :when, :while ]

  # various non-call constructs
  SCORES.merge!(:alias => 2,
                :assignment => 1,
                :block => 1,
                :block_pass => 1,
                :branch => 1,
                :lit_fixnum => 0.25,
                :sclass => 5,
                :super => 1,
                :to_proc_icky! => 10,
                :to_proc_normal => 5,
                :yield => 1)

  # eval forms
  SCORES.merge!(:define_method => 5,
                :eval => 5,
                :module_eval => 5,
                :class_eval => 5,
                :instance_eval => 5)

  # various "magic" usually used for "clever code"
  SCORES.merge!(:alias_method => 2,
                :extend => 2,
                :include => 2,
                :instance_method => 2,
                :instance_methods => 2,
                :method_added => 2,
                :method_defined? => 2,
                :method_removed => 2,
                :method_undefined => 2,
                :private_class_method => 2,
                :private_instance_methods => 2,
                :private_method_defined? => 2,
                :protected_instance_methods => 2,
                :protected_method_defined? => 2,
                :public_class_method => 2,
                :public_instance_methods => 2,
                :public_method_defined? => 2,
                :remove_method => 2,
                :send => 3,
                :undef_method => 2)

  # calls I don't like and usually see being abused
  SCORES.merge!(:inject => 2)

  @@no_class = :main
  @@no_method = :none

  attr_reader :calls
  attr_accessor :multiplier, :class_stack, :method_stack

  def initialize
    super
    @class_stack = []
    @method_stack = []
    self.auto_shift_type = true
    self.require_empty = false # HACK
    self.reset
  end
  
  def parse_tree
    @parse_tree ||= ParseTree.new(false)
  end

  def flog_files *files
    files.flatten.each do |file|
      flog_file(file)
    end
  end
  
  def flog_file(file)
    return flog_directory(file) if File.directory? file
    data = $stdin.read if file == '-'
    data ||= File.read(file)
    warn "** flogging #{file}" if $v
    flog(data, file)
  end
  
  def flog_directory(dir)
    Dir["#{dir}/**/*.rb"].each {|file| flog_file(file) }
  end
  
  def flog(ruby, file)
    process_parse_tree(ruby, file)
  rescue SyntaxError => e
    raise e unless e.inspect =~ /<%|%>/
    warn e.inspect + " at " + e.backtrace.first(5).join(', ')
    warn "...stupid lemmings and their bad erb templates... skipping"
  end
  
  def process_parse_tree(ruby, file)
    sexp = parse_tree.parse_tree_for_string(ruby, file)
    process Sexp.from_array(sexp).first
  end
  
  def add_to_score(name)
    @calls["#{self.class_name}##{self.method_name}"][name] += SCORES[name] * @multiplier
  end
  
  def average
    self.total / self.calls.size
  end
  
  def penalize_by bonus
    @multiplier += bonus
    yield
    @multiplier -= bonus
  end

  def analyze_list exp
    process exp.shift until exp.empty?
  end

  def set_class name
    @class_stack.unshift name
    yield
    @class_stack.shift
  end

  def class_name
    @class_stack.first || @@no_class
  end

  def method name
    @method_stack.unshift name
    yield
    @method_stack.shift
  end

  def method_name
    @method_stack.first || @@no_method
  end

  def reset
    @totals = @total_score = nil
    @multiplier = 1.0
    @calls = Hash.new { |h,k| h[k] = Hash.new 0 }
  end

  def total
    self.totals unless @total_score # calculates total_score as well

    @total_score
  end

  def totals
    unless @totals then
      @total_score = 0
      @totals = Hash.new(0)
      self.calls.each do |meth, tally|
        next if $m and meth =~ /##{@@no_method}$/
        a, b, c = 0, 0, 0
        tally.each do |cat, score|
          case cat
          when :assignment then a += score
          when :branch     then b += score
          else                  c += score
          end
        end
        score = Math.sqrt(a*a + b*b + c*c)
        @totals[meth] = score
        @total_score += score
      end
    end
    @totals
  end

  def report io = $stdout
    current = 0   # can be moved lower
    total_score = self.total
    max = total_score * THRESHOLD  # can be moved lower
    totals = self.totals  # can be moved lower

    io.puts "Total Flog = %.1f (%.1f flog / method)" % [total_score, self.average]
    io.puts

    exit 0 if $s

    @calls.sort_by { |k,v| -totals[k] }.each do |class_method, calls|
      next if $m and class_method =~ /##{@@no_method}/
      total = totals[class_method]
      io.puts "%s: (%.1f)" % [class_method, total]
      calls.sort_by { |k,v| -v }.each do |call, count|
        io.puts "  %6.1f: %s" % [count, call]
      end

      current += total
      break if current >= max
    end
  ensure
    self.reset
  end

  ############################################################
  # Process Methods:

  def process_alias(exp)
    process exp.shift
    process exp.shift
    add_to_score :alias
    s()
  end

  def process_and(exp)
    add_to_score :branch
    penalize_by 0.1 do
      process exp.shift # lhs
      process exp.shift # rhs
    end
    s()
  end

  def process_attrasgn(exp)
    add_to_score :assignment
    process exp.shift # lhs
    exp.shift # name
    process exp.shift # rhs
    s()
  end

  def process_attrset(exp)
    add_to_score :assignment
    raise exp.inspect
    s()
  end

  def process_block(exp)
    penalize_by 0.1 do
      analyze_list exp
    end
    s()
  end

  # [:block_pass, [:lit, :blah], [:fcall, :foo]]
  def process_block_pass(exp)
    arg = exp.shift
    call = exp.shift

    add_to_score :block_pass

    case arg.first
    when :lvar, :dvar, :ivar, :cvar, :self, :const, :nil then
      # do nothing
    when :lit, :call then
      add_to_score :to_proc_normal
    when :iter, *BRANCHING then
      add_to_score :to_proc_icky!
    else
      raise({:block_pass => [arg, call]}.inspect)
    end

    process arg
    process call

    s()
  end

  def process_call(exp)
    penalize_by 0.2 do
      recv = process exp.shift
    end
    name = exp.shift
    penalize_by 0.2 do
      args = process exp.shift
    end

    add_to_score name

    s()
  end

  def process_case(exp)
    add_to_score :branch
    process exp.shift # recv
    penalize_by 0.1 do
      analyze_list exp
    end
    s()
  end

  def process_class(exp)
    set_class exp.shift do
      penalize_by 1.0 do
        supr = process exp.shift
      end
      analyze_list exp
    end
    s()
  end

  def process_dasgn_curr(exp)
    add_to_score :assignment
    exp.shift # name
    process exp.shift # assigment, if any
    s()
  end

  def process_defn(exp)
    self.method exp.shift do
      analyze_list exp
    end
    s()
  end

  def process_defs(exp)
    process exp.shift
    self.method exp.shift do
      analyze_list exp
    end
    s()
  end

  def process_else(exp)
    add_to_score :branch
    penalize_by 0.1 do
      analyze_list exp
    end
    s()
  end

  def process_iasgn(exp)
    add_to_score :assignment
    exp.shift # name
    process exp.shift # rhs
    s()
  end

  def process_if(exp)
    add_to_score :branch
    process exp.shift # cond
    penalize_by 0.1 do
      process exp.shift # true
      process exp.shift # false
    end
    s()
  end

  def process_iter(exp)
    context = (self.context - [:class, :module, :scope])
    if context.uniq.sort_by {|s|s.to_s} == [:block, :iter] then
      recv = exp.first
      if recv[0] == :call and recv[1] == nil and recv.arglist[1] and [:lit, :str].include? recv.arglist[1][0] then
        msg = recv[2]
        submsg = recv.arglist[1][1]
        self.method submsg do
          set_class msg do
            analyze_list exp
          end
        end
        return s()
      end
    end

    add_to_score :branch

    process exp.shift # no penalty for LHS

    penalize_by 0.1 do
      analyze_list exp
    end

    s()
  end

  def process_lasgn(exp)
    add_to_score :assignment
    exp.shift # name
    process exp.shift # rhs
    s()
  end

  def process_lit(exp)
    value = exp.shift
    case value
    when 0, -1 then
      # ignore those because they're used as array indicies instead of first/last
    when Integer then
      add_to_score :lit_fixnum
    when Float, Symbol, Regexp, Range then
      # do nothing
    else
      raise value.inspect
    end
    s()
  end

  def process_masgn(exp)
    add_to_score :assignment
    process exp.shift # lhs
    process exp.shift # rhs
    s()
  end

  def process_module(exp)
    set_class exp.shift do
      analyze_list exp
    end
    s()
  end

  def process_or(exp)
    add_to_score :branch
    penalize_by 0.1 do
      process exp.shift # lhs
      process exp.shift # rhs
    end
    s()
  end

  def process_rescue(exp)
    add_to_score :branch
    penalize_by 0.1 do
      analyze_list exp
    end
    s()
  end

  def process_sclass(exp)
    penalize_by 0.5 do
      recv = process exp.shift
      analyze_list exp
    end

    add_to_score :sclass
    s()
  end

  def process_super(exp)
    add_to_score :super
    analyze_list exp
    s()
  end

  def process_until(exp)
    add_to_score :branch
    penalize_by 0.1 do
      process exp.shift # cond
      process exp.shift # body
    end
    exp.shift # pre/post
    s()
  end

  def process_when(exp)
    add_to_score :branch
    penalize_by 0.1 do
      analyze_list exp
    end
    s()
  end

  def process_while(exp)
    add_to_score :branch
    penalize_by 0.1 do
      process exp.shift # cond
      process exp.shift # body
    end
    exp.shift # pre/post
    s()
  end

  def process_yield(exp)
    add_to_score :yield
    analyze_list exp
    s()
  end
end
