require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe 'flog command' do
  before :all do
    path = File.join(File.dirname(__FILE__), *%w[.. bin])
    ENV['PATH'] = [path, ENV['PATH']].join(':')
  end

  before :each do
    @flog = stub('Flog', :flog_files => true, :report => true)
    Flog.stubs(:new).returns(@flog)
    self.stubs(:exit)
  end

  def run_command
    eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin flog]))
  end
  
  describe 'when no command-line arguments are specified' do
    before :each do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
  
    it 'should run' do
      lambda { run_command }.should_not raise_error(Errno::ENOENT)
    end
    
    it 'should create a Flog instance' do
      Flog.expects(:new).returns(@flog)
      run_command
    end
    
    it 'should call flog_files on the Flog instance' do
      @flog.expects(:flog_files)
      run_command
    end
    
    it 'should call report on the Flog instance' do
      @flog.expects(:report)
      run_command
    end
    
    it "should pass '-' (for the file path) to flog_files on the instance" do
      @flog.expects(:flog_files).with(['-'])
      run_command
    end
  end
  
  describe "since the script assumes it was called with 'ruby -s'" do
    describe "when -h is specified on the command-line" do
      before :each do
        Object.send(:remove_const, :ARGV)
        ARGV = []
        $h = true  # ruby -s, ftw
      end
      
      after :each do
        $h = nil
      end
      
      before :each do
        self.stubs(:puts).returns(nil)
      end
    
      it "should display help information" do
        self.expects(:puts).at_least_once
        run_command
      end
      
      it 'should not create a Flog instance' do
        Flog.expects(:new).never
        run_command
      end
      
      it 'should exit with status 0' do
        self.expects(:exit).with(0)
        run_command
      end
    end
    
    describe 'when -I is specified on the command-line' do
      before :each do
        Object.send(:remove_const, :ARGV)
        ARGV = []
      end
      
      before :each do
        @paths = $:.dup
      end
      
      describe 'when -I is not given a string' do
        before :each do
          $I = 234  # ruby -s, ftw
        end
        
        after :each do
          $I = nil
        end
        
        it '(currently) should not modify the include path' do
          run_command
          $:.should == @paths
        end
        
        it 'should display usage'
        it 'should not create a Flog instance'
      end
      
      describe 'when -I is given a string' do
        before :each do
          $I = '/bin/true'      
        end
        
        after :each do
          $I = nil
        end
        
        it "should append each ':' separated path to $:" do
          run_command
          $:.should_not == @paths
        end
      end
      
      it 'should create a Flog instance' do
        Flog.expects(:new).returns(@flog)
        run_command
      end
    end
  end
end