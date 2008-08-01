require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe 'flog command' do
  before :each do
    @flog = stub('Flog', :flog_files => true, :report => true)
    Flog.stubs(:new).returns(@flog)
    self.stubs(:exit)
  end

  def run_command
    eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin flog]))
  end
  
  describe 'usage' do
    it 'should take no arguments' do
      run_command
      lambda { usage('foo') }.should raise_error(ArgumentError)
    end
    
    it 'should output a usage message' do
      run_command
      self.expects(:puts).at_least_once
      usage
    end
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

    it 'should not display usage information' do
      self.expects(:usage).never
      run_command
    end

    it 'should not alter the include path' do
      @paths = $:.dup
      run_command
      $:.should == @paths
    end
    
    it 'should not display all flog results' do
      run_command
      $a.should be_false
    end
    
    it 'should not display a summary report' do
      run_command
      $s.should be_false
    end
    
    it 'should not skip code outside of methods' do
      run_command
      $m.should be_false
    end
    
    it 'should not display verbose progress info' do
      run_command
      $v.should be_false
    end
  end
  
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
      self.stubs(:usage).returns(nil)
    end
  
    currently "should display help information" do
      self.expects(:usage)
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
      
      currently 'should not modify the include path' do
        run_command
        $:.should == @paths
      end
      
      it 'should display usage' do
        self.expects(:usage)
        run_command
      end
      
      it 'should not create a Flog instance' do
        Flog.expects(:new).never
        run_command
      end
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