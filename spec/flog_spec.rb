require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

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
    
    it 'should not have any calls yet' do
      @flog.calls.should == {}
    end
    
    it 'should have a means of accessing its parse tree' do
      @flog.should respond_to(:parse_tree)
    end
  end
  
  describe 'when accessing the parse tree' do
    before :each do
      @parse_tree = stub('parse tree')
      ParseTree.stubs(:new).returns(@parse_tree)
    end
    
    describe 'for the first time' do
      it 'should create a new ParseTree' do
        ParseTree.expects(:new)
        @flog.parse_tree
      end
      
      it 'should leave newlines off when creating the ParseTree instance' do
        ParseTree.expects(:new).with(false)
        @flog.parse_tree
      end
      
      it 'should return a ParseTree instance' do
        @flog.parse_tree.should == @parse_tree
      end
    end
    
    describe 'after the parse tree has been initialized' do
      before :each do
        @flog.parse_tree
      end
      
      it 'should not attempt to create a new ParseTree instance' do
        ParseTree.expects(:new).never
        @flog.parse_tree
      end
      
      it 'should return a ParseTree instance' do
        @flog.parse_tree.should == @parse_tree
      end
    end
  end
  
  describe "when flogging a list of files" do
    describe 'when no files are specified' do
      it 'should not raise an exception' do
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
          
          it 'should note which file is being flogged' do
            @flog.expects(:warn)
            @flog.flog_file('-')
          end
        end
        
        describe 'when the verbose flag is off' do
          before :each do
            $v = false
          end
          
          it 'should note which file is being flogged' do
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

        it 'should expand the files in the directory' do
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
          
          it 'should note which file is being flogged' do
            @flog.expects(:warn)
            @flog.flog_file(@file)
          end
        end
        
        describe 'when the verbose flag is off' do
          before :each do
            $v = false
          end
          
          it 'should note which file is being flogged' do
            @flog.expects(:warn).never
            @flog.flog_file(@file)
          end          
        end
      end
    end
  end

  describe 'when flogging a directory' do
    before :each do
      @files = ['a', 'b', 'c', 'd']
      @dir = File.dirname(__FILE__)
      @flog.stubs(:flog_file)
      Dir.stubs(:new).returns(@files)
    end
    
    it 'should get the list of files in the directory' do
      Dir.expects(:new).returns(@files)
      @flog.flog_directory(@dir)
    end
    
    it 'should call flog_file once for each file in the directory' do
      @flog.expects(:flog_file).times(@files.size)
      @flog.flog_directory(@dir)
    end
    
    it 'should pass the filename to flog_file for each file in the directory' do
      @files.each do |file|
        @flog.expects(:flog_file).with(file)
      end
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
        it 'should warn about skipping' do
          @flog.expects(:warn).at_least_once
          @flog.flog('string', 'filename')
        end
        
        it 'should not raise an exception' do
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
    it 'should compute the parse tree for the ruby string'
    it 'should use both the ruby string and the filename when computing the parse tree'
    
    describe 'if the ruby string is valid' do
      it 'should convert the parse tree into a list of S-expressions'
      it 'should process the list of S-expressions'
      it 'should start processing at the first S-expression'
    end
    
    describe 'if the ruby string is invalid' do
      it 'should fail'
      it 'should not attempt to process the parse tree'
    end
  end
end