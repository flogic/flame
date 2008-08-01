require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'
require 'sexp_processor'

describe Flog do
  before :each do
    @flog = Flog.new
  end

  describe 'when initializing' do
    it 'should allow no arguments' do
      lambda { Flog.new 'bogus' }.should raise_error(ArgumentError)
    end
    
    it 'should succeed if given no arguments' do
      lambda { Flog.new }.should_not raise_error
    end
    
    it 'should not reference the parse tree' do
      ParseTree.expects(:new).never
      Flog.new
    end
  end
  
  describe 'after initializing' do
    it 'may need to verify more state than these specs currently do'
    
    it 'should return an SexpProcessor' do
      @flog.should be_a_kind_of(SexpProcessor)
    end
    
    it 'should be initialized like all SexpProcessors' do
      # less than ideal means of insuring the Flog instance was initialized properly, imo -RB
      @flog.context.should == []  
    end
    
    currently 'should not have any calls yet' do
      @flog.calls.should == {}
    end
    
    it 'should have a means of accessing its parse tree' do
      @flog.should respond_to(:parse_tree)
    end
  end
  
  describe 'when accessing the parse tree' do
    before :each do
      @parse_tree = stub('parse tree')
    end
    
    describe 'for the first time' do
      it 'should create a new ParseTree' do
        ParseTree.expects(:new)
        @flog.parse_tree
      end
      
      currently 'should leave newlines off when creating the ParseTree instance' do
        ParseTree.expects(:new).with(false)
        @flog.parse_tree
      end
      
      it 'should return a ParseTree instance' do
        ParseTree.stubs(:new).returns(@parse_tree)
        @flog.parse_tree.should == @parse_tree
      end
    end
    
    describe 'after the parse tree has been initialized' do
      it 'should not attempt to create a new ParseTree instance' do
        @flog.parse_tree
        ParseTree.expects(:new).never
        @flog.parse_tree
      end
      
      it 'should return a ParseTree instance' do
        ParseTree.stubs(:new).returns(@parse_tree)
        @flog.parse_tree
        @flog.parse_tree.should == @parse_tree
      end
    end
  end
  
  describe "when flogging a list of files" do
    describe 'when no files are specified' do
      currently 'should not raise an exception' do
        lambda { @flog.flog_files }.should_not raise_error
      end
      
      it 'should never call flog_file' do
        @flog.expects(:flog_file).never
        @flog.flog_files
      end
    end
    
    describe 'when files are specified' do
      before :each do
        @files = [1, 2, 3, 4]
        @flog.stubs(:flog_file)
      end
      
      it 'should do a flog for each individual file' do
        @flog.expects(:flog_file).times(@files.size)
        @flog.flog_files(@files)
      end
      
      it 'should provide the filename when flogging a file' do
        @files.each do |file|
          @flog.expects(:flog_file).with(file)
        end
        @flog.flog_files(@files)          
      end
    end
    
    describe 'when flogging a single file' do
      before :each do
        @flog.stubs(:flog)
      end
      
      describe 'when the filename is "-"' do
        before :each do
          @stdin = $stdin  # HERE: working through the fact that zenspider is using $stdin in the middle of the system
          $stdin = stub('stdin', :read => 'data')
        end

        after :each do
          $stdin = @stdin
        end

        it 'should not raise an exception' do
          lambda { @flog.flog_file('-') }.should_not raise_error
        end

        it 'should read the data from stdin' do
          $stdin.expects(:read).returns('data')
          @flog.flog_file('-')
        end
        
        it 'should flog the read data' do
          @flog.expects(:flog).with('data', '-')
          @flog.flog_file('-')
        end
        
        describe 'when the verbose flag is on' do
          before :each do
            $v = true
          end
          
          after :each do
            $v = false
          end
          
          currently 'should note which file is being flogged' do
            @flog.expects(:warn)
            @flog.flog_file('-')
          end
        end
        
        describe 'when the verbose flag is off' do
          before :each do
            $v = false
          end
          
          currently 'should note which file is being flogged' do
            @flog.expects(:warn).never
            @flog.flog_file('-')
          end          
        end
      end
      
      describe 'when the filename points to a directory' do
        before :each do
          @flog.stubs(:flog_directory)
          @file = File.dirname(__FILE__)
        end

        it 'should expand the files under the directory' do
          @flog.expects(:flog_directory)
          @flog.flog_file(@file)
        end
        
        it 'should not read data from stdin' do
          $stdin.expects(:read).never
          @flog.flog_file(@file)          
        end
        
        it 'should not flog any data' do
          @flog.expects(:flog).never
          @flog.flog_file(@file)
        end
      end
      
      describe 'when the filename points to a non-existant file' do
        before :each do
          @file = '/adfasdfasfas/fasdfaf-#{rand(1000000).to_s}'
        end
        
        it 'should raise an exception' do
          lambda { @flog.flog_file(@file) }.should raise_error(Errno::ENOENT)
        end
      end
      
      describe 'when the filename points to an existing file' do
        before :each do
          @file = __FILE__
          File.stubs(:read).returns('data')
        end
        
        it 'should read the contents of the file' do
          File.expects(:read).with(@file).returns('data')
          @flog.flog_file(@file)
        end
        
        it 'should flog the contents of the file' do
          @flog.expects(:flog).with('data', @file)
          @flog.flog_file(@file)
        end
        
        describe 'when the verbose flag is on' do
          before :each do
            $v = true
          end
          
          after :each do
            $v = false
          end
          
          currently 'should note which file is being flogged' do
            @flog.expects(:warn)
            @flog.flog_file(@file)
          end
        end
        
        describe 'when the verbose flag is off' do
          before :each do
            $v = false
          end
          
          currently 'should note which file is being flogged' do
            @flog.expects(:warn).never
            @flog.flog_file(@file)
          end          
        end
      end
    end
  end

  describe 'when flogging a directory' do
    before :each do
      @files = ['a.rb', '/foo/b.rb', '/foo/bar/c.rb', '/foo/bar/baz/d.rb']
      @dir = File.dirname(__FILE__)
      Dir.stubs(:[]).returns(@files)
    end
    
    it 'should get the list of ruby files under the directory' do
      @flog.stubs(:flog_file)
      Dir.expects(:[]).returns(@files)
      @flog.flog_directory(@dir)
    end
    
    it "should call flog_file once for each file in the directory" do
      @files.each {|f| @flog.expects(:flog_file).with(f) }
      @flog.flog_directory(@dir)
    end
  end

  describe 'when flogging a Ruby string' do
    it 'should require both a Ruby string and a filename' do
      lambda { @flog.flog('string') }.should raise_error(ArgumentError)
    end
    
    describe 'when the string has a syntax error' do
      before :each do
        @flog.stubs(:process_parse_tree).raises(SyntaxError.new("<% foo %>"))
      end
      
      describe 'when the string has erb snippets' do
        currently 'should warn about skipping' do
          @flog.expects(:warn).at_least_once
          @flog.flog('string', 'filename')
        end
        
        currently 'should not raise an exception' do
          lambda { @flog.flog('string', 'filename') }.should_not raise_error
        end
        
        it 'should not process the failing code' do
          @flog.expects(:process).never
          @flog.flog('string', 'filename')
        end
      end
      
      describe 'when the string has no erb snippets' do
        before :each do
          @flog.stubs(:process_parse_tree).raises(SyntaxError)
        end
        
        it 'should raise a SyntaxError exception' do
          lambda { @flog.flog('string', 'filename') }.should raise_error(SyntaxError)
        end
        
        it 'should not process the failing code' do
          @flog.expects(:process).never
          lambda { @flog.flog('string', 'filename') }
        end
      end
    end
    
    describe 'when the string contains valid Ruby' do
      before :each do
        @flog.stubs(:process_parse_tree)
      end
      
      it 'should process the parse tree for the string' do
        @flog.expects(:process_parse_tree)
        @flog.flog('string', 'filename')
      end
      
      it 'should provide the string and the filename to the parse tree processor' do
        @flog.expects(:process_parse_tree).with('string', 'filename')
        @flog.flog('string', 'filename')
      end
    end
  end
  
  describe 'when processing a ruby parse tree' do
    before :each do
      @flog.stubs(:process)
      @sexp = stub('s-expressions')
      @parse_tree = stub('parse tree', :parse_tree_for_string => @sexp)
      ParseTree.stubs(:new).returns(@parse_tree)
    end
    
    it 'should require both a ruby string and a filename' do
      lambda { @flog.process_parse_tree('string') }.should raise_error(ArgumentError)
    end
    
    it 'should compute the parse tree for the ruby string' do
      Sexp.stubs(:from_array).returns(['1', '2'])
      @parse_tree.expects(:parse_tree_for_string).returns(@sexp)
      @flog.process_parse_tree('string', 'file')
    end
    
    it 'should use both the ruby string and the filename when computing the parse tree' do
      Sexp.stubs(:from_array).returns(['1', '2'])
      @parse_tree.expects(:parse_tree_for_string).with('string', 'file').returns(@sexp)
      @flog.process_parse_tree('string', 'file')      
    end
    
    describe 'if the ruby string is valid' do
      before :each do
        @parse_tree = stub('parse tree', :parse_tree_for_string => @sexp)
        @flog.stubs(:process)
        @flog.stubs(:parse_tree).returns(@parse_tree)        
      end
      
      currently 'should convert the parse tree into a list of S-expressions' do
        Sexp.expects(:from_array).with(@sexp).returns(['1', '2'])
        @flog.process_parse_tree('string', 'file')
      end
      
      currently 'should process the list of S-expressions' do
        @flog.expects(:process)
        @flog.process_parse_tree('string', 'file')
      end
      
      currently 'should start processing at the first S-expression' do
        Sexp.stubs(:from_array).returns(['1', '2'])
        @flog.expects(:process).with('1')
        @flog.process_parse_tree('string', 'file')        
      end
    end
    
    describe 'if the ruby string is invalid' do
      before :each do
        @parse_tree = stub('parse tree')
        @flog.stubs(:parse_tree).returns(@parse_tree)        
        @parse_tree.stubs(:parse_tree_for_string).raises(SyntaxError)
      end
      
      currently 'should fail' do
        lambda { @flog.process_parse_tree('string', 'file') }.should raise_error(SyntaxError)
      end
      
      currently 'should not attempt to process the parse tree' do
        @flog.expects(:process).never
        lambda { @flog.process_parse_tree('string', 'file') }
      end
    end
  end
  
  describe 'multiplier' do
    it 'should be possible to determine the current value of the multiplier' do
      @flog.should respond_to(:multiplier)
    end
  
    it 'should be possible to set the current value of the multiplier' do
      @flog.multiplier = 10
      @flog.multiplier.should == 10
    end
  end
  
  describe 'class_stack' do
    it 'should be possible to determine the current value of the class stack' do
      @flog.should respond_to(:class_stack)
    end
  
    it 'should be possible to set the current value of the class stack' do
      @flog.class_stack = [ 'name' ]
      @flog.class_stack.should == [ 'name' ]
    end
  end
  
  describe 'method_stack' do
    it 'should be possible to determine the current value of the method stack' do
      @flog.should respond_to(:method_stack)
    end
  
    it 'should be possible to set the current value of the method stack' do
      @flog.method_stack = [ 'name' ]
      @flog.method_stack.should == [ 'name' ]
    end
  end
  
  describe 'when adding to the current flog score' do
    before :each do
      @flog.multiplier = 1
      @flog.stubs(:klass_name).returns('foo')
      @flog.stubs(:method_name).returns('bar')
      @flog.calls['foo#bar'] = { :alias => 0 }
    end
    
    it 'should require an operation name' do
      lambda { @flog.add_to_score() }.should raise_error(ArgumentError)
    end
    
    it 'should update the score for the current class, method, and operation' do
      @flog.add_to_score(:alias)
      @flog.calls['foo#bar'][:alias].should_not == 0
    end
    
    it 'should use the multiplier when updating the current call score' do
      @flog.multiplier = 10
      @flog.add_to_score(:alias)
      @flog.calls['foo#bar'][:alias].should == 10*Flog::SCORES[:alias]
    end
  end
  
  describe 'when computing the average per-call flog score' do
    it 'should not allow arguments' do
      lambda { @flog.average('foo') }.should raise_error(ArgumentError)
    end
    
    it 'should return the total flog score divided by the number of calls' do
      @flog.stubs(:total).returns(100.0)
      @flog.stubs(:calls).returns({ :bar => {}, :foo => {} })
      @flog.average.should be_close(100.0/2, 0.00000000001)
    end
  end

  describe 'when recursively analyzing the complexity of code' do
    it 'should require a complexity modifier value' do
      lambda { @flog.bad_dog! }.should raise_error(ArgumentError)
    end
    
    it 'should require a block, for code to recursively analyze' do
      lambda { @flog.bad_dog!(42) }.should raise_error(LocalJumpError)
    end
    
    it 'should recursively analyze the provided code block' do
      @flog.bad_dog!(42) do
        @foo = true
      end
      
      @foo.should be_true
    end
    
    it 'should update the complexity multiplier when recursing' do
      @flog.multiplier = 1
      @flog.bad_dog!(42) do
        @flog.multiplier.should == 43
      end
    end
    
    it 'when it is done it should restore the complexity multiplier to its original value' do
      @flog.multiplier = 1
      @flog.bad_dog!(42) do
      end
      @flog.multiplier.should == 1
    end
  end
  
  describe 'when computing complexity of all remaining opcodes' do
    it 'should require a list of opcodes' do
      lambda { @flog.bleed }.should raise_error(ArgumentError)
    end
    
    it 'should process each opcode' do
      @opcodes = [ :foo, :bar, :baz ]
      @opcodes.each do |opcode|
         @flog.expects(:process).with(opcode)
      end
      
      @flog.bleed @opcodes
    end
  end
  
  describe 'when recording the current class being analyzed' do
    it 'should require a class name' do
      lambda { @flog.klass }.should raise_error(ArgumentError)
    end
    
    it 'should require a block during which the class name is in effect' do
      lambda { @flog.klass('name') }.should raise_error(LocalJumpError)
    end
    
    it 'should recursively analyze the provided code block' do
      @flog.klass 'name' do
        @foo = true
      end
      
      @foo.should be_true
    end
    
    it 'should update the class stack when recursing' do
      @flog.class_stack = []
      @flog.klass 'name' do
        @flog.class_stack.should == ['name']
      end
    end
    
    it 'when it is done it should restore the class stack to its original value' do
      @flog.class_stack = []
      @flog.klass 'name' do
      end
      @flog.class_stack.should == []
    end
  end
  
  describe 'when looking up the name of the class currently under analysis' do
    it 'should not take any arguments' do
      lambda { @flog.klass_name('foo') }.should raise_error(ArgumentError)
    end
    
    it 'should return the most recent class entered' do
      @flog.class_stack = [:foo, :bar, :baz]
      @flog.klass_name.should == :foo
    end
    
    it 'should return the default class if no classes entered' do
      @flog.class_stack = []
      @flog.klass_name.should == :main
    end
  end

  describe 'when recording the current method being analyzed' do
    it 'should require a method name' do
      lambda { @flog.method }.should raise_error(ArgumentError)
    end
    
    it 'should require a block during which the class name is in effect' do
      lambda { @flog.method('name') }.should raise_error(LocalJumpError)
    end
    
    it 'should recursively analyze the provided code block' do
      @flog.method 'name' do
        @foo = true
      end
      
      @foo.should be_true
    end
    
    it 'should update the class stack when recursing' do
      @flog.method_stack = []
      @flog.method 'name' do
        @flog.method_stack.should == ['name']
      end
    end
    
    it 'when it is done it should restore the class stack to its original value' do
      @flog.method_stack = []
      @flog.method 'name' do
      end
      @flog.method_stack.should == []
    end
  end

  describe 'when looking up the name of the method currently under analysis' do
    it 'should not take any arguments' do
      lambda { @flog.method_name('foo') }.should raise_error(ArgumentError)
    end
    
    it 'should return the most recent class entered' do
      @flog.method_stack = [:foo, :bar, :baz]
      @flog.method_name.should == :foo
    end
    
    it 'should return the default class if no classes entered' do
      @flog.method_stack = []
      @flog.method_name.should == :none
    end
  end
  
  describe 'when resetting state' do
    it 'should not take any arguments' do
      lambda { @flog.reset('foo') }.should raise_error(ArgumentError)
    end
    
    it 'should clear any recorded totals data' do
      @flog.totals['foo'] = 'bar'
      @flog.reset
      @flog.totals.should == {}
    end
        
    it 'should clear the total score' do
      # the only way I know to do this is to force the total score to be computed for actual code, then reset it
      @flog.flog_files(fixture_files('/simple/simple.rb'))
      @flog.reset
      @flog.total.should == 0
    end
    
    it 'should set the multiplier to 1.0' do
      @flog.multiplier = 20.0
      @flog.reset
      @flog.multiplier.should == 1.0
    end
    
    it 'should set clear any calls data' do
      @flog.calls['foobar'] = 'yoda'
      @flog.reset
      @flog.calls.should == {}
    end
    
    it 'should ensure that new recorded calls will get 0 counts without explicit initialization' do
      @flog.reset
      @flog.calls['foobar']['baz'] += 20
      @flog.calls['foobar']['baz'].should == 20
    end
  end

  describe 'when generating a report' do
    it 'allows specifying an io handle'
    it 'defaults the io handle to stdout'
    it 'computes the total flog score'
    it 'retrieves the set of total statistics'
    
    it 'outputs the total flog score'
    it 'computes the average flog score'
    it 'outputs the average flog score'
    
    describe 'when summary mode is set' do
      it 'exits with status 0'
      it 'does not produce a call listing'
      it 'should not retrieve the set of total statistics'
    end
    
    describe 'when summary mode is not set' do
      
    end
  end
end