require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'

describe 'flog command' do
  def run_command
    eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin flog]))
  rescue SystemExit
  end
  
  describe 'when no command-line arguments are specified' do
    before :all do
      path = File.join(File.dirname(__FILE__), *%w[.. bin])
      ENV['PATH'] = [path, ENV['PATH']].join(':')
    end
  
    before :each do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
  
    before :each do
      @flog = stub('Flog', :flog_files => true, :report => true)
      Flog.stubs(:new).returns(@flog)
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
end